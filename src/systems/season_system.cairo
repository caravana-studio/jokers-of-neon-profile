use starknet::ContractAddress;
use crate::models::{Season, SeasonReward, SeasonLevelConfig, MissionXPConfig, LevelXPConfig};

#[starknet::interface]
pub trait ISeasonSystem<T> {
    // Season management
    fn create_season(
        ref self: T, id: u32, name: ByteArray, start_date: u64, end_date: u64,
    ) -> Season;
    fn activate_season(ref self: T, season_id: u32);
    fn deactivate_season(ref self: T, season_id: u32);
    fn get_season(self: @T, season_id: u32) -> Season;

    // Reward management
    fn create_reward(
        ref self: T, id: u32, reward_type: u8, value: u256, description: ByteArray,
    ) -> SeasonReward;
    fn get_reward(self: @T, reward_id: u32) -> SeasonReward;

    // Configuration methods
    fn configure_season_level(
        ref self: T,
        season_id: u32,
        level: u32,
        required_xp: u256,
        free_rewards: Span<u32>,
        premium_rewards: Span<u32>,
    );

    // Season Pass purchase
    fn purchase_season_pass(ref self: T, address: ContractAddress, season_id: u32);

    // Reward claiming
    fn claim_reward(ref self: T, address: ContractAddress, season_id: u32, level: u32, is_premium: bool);
    fn claim_all_available_rewards(ref self: T, address: ContractAddress, season_id: u32);

    // User initialization
    fn initialize_user_progress(ref self: T, address: ContractAddress, season_id: u32);

    // View methods
    fn get_claimable_rewards(
        self: @T, address: ContractAddress, season_id: u32,
    ) -> (Span<u32>, Span<u32>); // (free_levels, premium_levels)
    fn is_reward_claimed(
        self: @T, address: ContractAddress, season_id: u32, level: u32, is_premium: bool,
    ) -> bool;
    fn get_user_progress(
        self: @T, address: ContractAddress, season_id: u32,
    ) -> (u256, u32, bool); // (xp, level, has_pass)
    fn has_season_pass(self: @T, address: ContractAddress, season_id: u32) -> bool;

    // Season configuration methods
    fn set_season_level_config(ref self: T, config: SeasonLevelConfig);
    fn set_mission_xp_config(ref self: T, config: MissionXPConfig);
    fn set_level_xp_config(ref self: T, config: LevelXPConfig);
    fn setup_default_season_config(ref self: T, season_id: u32);
    fn get_season_level_config_by_level(self: @T, season_id: u32, level: u32) -> SeasonLevelConfig;
    fn get_season_level_config_by_address(
        self: @T, address: ContractAddress, season_id: u32,
    ) -> SeasonLevelConfig;
}

#[dojo::contract]
pub mod season_system {
    use core::num::traits::Zero;
    use starknet::{ContractAddress, get_block_timestamp};
    use crate::models::{
        ClaimedReward, Season, SeasonLevelConfig, SeasonProgress, SeasonReward, MissionXPConfig,
        LevelXPConfig,
    };
    use crate::store::{Store, StoreTrait};
    use super::ISeasonSystem;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SeasonCreated: SeasonCreated,
        SeasonActivated: SeasonActivated,
        SeasonDeactivated: SeasonDeactivated,
        RewardCreated: RewardCreated,
        SeasonPassPurchased: SeasonPassPurchased,
        RewardClaimed: RewardClaimed,
        SeasonLevelReached: SeasonLevelReached,
        UserProgressInitialized: UserProgressInitialized,
    }

    #[derive(Drop, starknet::Event)]
    struct SeasonCreated {
        #[key]
        season_id: u32,
        name: ByteArray,
        start_date: u64,
        end_date: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct SeasonActivated {
        #[key]
        season_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct SeasonDeactivated {
        #[key]
        season_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardCreated {
        #[key]
        reward_id: u32,
        reward_type: u8,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct SeasonPassPurchased {
        #[key]
        player: ContractAddress,
        season_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardClaimed {
        #[key]
        player: ContractAddress,
        season_id: u32,
        level: u32,
        is_premium: bool,
        reward_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct SeasonLevelReached {
        #[key]
        player: ContractAddress,
        season_id: u32,
        level: u32,
        xp: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct UserProgressInitialized {
        #[key]
        player: ContractAddress,
        season_id: u32,
    }

    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");

    fn dojo_init(ref self: ContractState, owner: ContractAddress) {}

    #[abi(embed_v0)]
    impl SeasonSystemImpl of ISeasonSystem<ContractState> {
        fn create_season(
            ref self: ContractState, id: u32, name: ByteArray, start_date: u64, end_date: u64,
        ) -> Season {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season = Season { id, name: name.clone(), is_active: false, start_date, end_date };

            store.set_season(season);

            self.emit(SeasonCreated { season_id: id, name: name.clone(), start_date, end_date });

            Season { id, name, is_active: false, start_date, end_date }
        }

        fn activate_season(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let mut season = store.get_season(season_id);
            assert(!season.is_active, 'Season already active');

            season.is_active = true;
            store.set_season(season);

            self.emit(SeasonActivated { season_id });
        }

        fn deactivate_season(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let mut season = store.get_season(season_id);
            assert(season.is_active, 'Season not active');

            season.is_active = false;
            store.set_season(season);

            self.emit(SeasonDeactivated { season_id });
        }

        fn get_season(self: @ContractState, season_id: u32) -> Season {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            store.get_season(season_id)
        }

        fn create_reward(
            ref self: ContractState,
            id: u32,
            reward_type: u8,
            value: u256,
            description: ByteArray,
        ) -> SeasonReward {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let reward = SeasonReward { id, reward_type, value, description: description.clone() };

            store.set_season_reward(reward);

            self.emit(RewardCreated { reward_id: id, reward_type, value });

            SeasonReward { id, reward_type, value, description }
        }

        fn get_reward(self: @ContractState, reward_id: u32) -> SeasonReward {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            store.get_season_reward(reward_id)
        }

        fn purchase_season_pass(
            ref self: ContractState, address: ContractAddress, season_id: u32,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season = store.get_season(season_id);
            assert(season.is_active, 'Season not active');

            let mut progress = store.get_season_progress(address, season_id);
            assert(!progress.has_season_pass, 'Already has season pass');

            progress.has_season_pass = true;
            store.set_season_progress(progress);

            // Auto-grant all premium rewards for already reached levels
            self._grant_retroactive_premium_rewards(ref store, address, season_id, progress.level);

            self.emit(SeasonPassPurchased { player: address, season_id });
        }

        fn claim_reward(
            ref self: ContractState,
            address: ContractAddress,
            season_id: u32,
            level: u32,
            is_premium: bool,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season = store.get_season(season_id);
            assert(season.is_active, 'Season not active');

            let progress = store.get_season_progress(address, season_id);

            // Verify user has reached this level
            assert(progress.level >= level, 'Level not reached');

            // Verify user has season pass if claiming premium reward
            if is_premium {
                assert(progress.has_season_pass, 'No season pass');
            }

            // Check if already claimed
            let claimed = store.get_claimed_reward(address, season_id, level, is_premium);
            assert(claimed.address.is_zero(), 'Reward already claimed');

            // Get the reward for this level
            let level_config = store.get_season_level_config(season_id, level);
            let rewards = if is_premium {
                level_config.premium_rewards
            } else {
                level_config.free_rewards
            };

            assert(rewards.len() > 0, 'No reward for this level');

            // Grant the rewards
            self._grant_rewards(ref store, address, rewards);

            // Mark as claimed
            let claimed_reward = ClaimedReward {
                address,
                season_id,
                level,
                is_premium,
                claimed_at: get_block_timestamp()
            };
            store.set_claimed_reward(claimed_reward);

            // Emit event for the first reward (in reality you might want to emit for all)
            let reward_id = *rewards.at(0);
            self.emit(RewardClaimed { player: address, season_id, level, is_premium, reward_id });
        }

        fn claim_all_available_rewards(
            ref self: ContractState, address: ContractAddress, season_id: u32,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season = store.get_season(season_id);
            assert(season.is_active, 'Season not active');

            let progress = store.get_season_progress(address, season_id);

            // Claim all free rewards up to current level
            let mut level = 1;
            loop {
                if level > progress.level {
                    break;
                }

                // Check if free reward is claimed
                let claimed_free = store.get_claimed_reward(address, season_id, level, false);
                if claimed_free.address.is_zero() {
                    let level_config = store.get_season_level_config(season_id, level);
                    if level_config.free_rewards.len() > 0 {
                        self._grant_rewards(ref store, address, level_config.free_rewards);
                        let claimed_reward = ClaimedReward {
                            address,
                            season_id,
                            level,
                            is_premium: false,
                            claimed_at: get_block_timestamp()
                        };
                        store.set_claimed_reward(claimed_reward);

                        let reward_id = *level_config.free_rewards.at(0);
                        self
                            .emit(
                                RewardClaimed {
                                    player: address,
                                    season_id,
                                    level,
                                    is_premium: false,
                                    reward_id,
                                },
                            );
                    }
                }

                // If has season pass, claim premium rewards too
                if progress.has_season_pass {
                    let claimed_premium = store.get_claimed_reward(address, season_id, level, true);
                    if claimed_premium.address.is_zero() {
                        let level_config = store.get_season_level_config(season_id, level);
                        if level_config.premium_rewards.len() > 0 {
                            self._grant_rewards(ref store, address, level_config.premium_rewards);
                            let claimed_reward = ClaimedReward {
                                address,
                                season_id,
                                level,
                                is_premium: true,
                                claimed_at: get_block_timestamp()
                            };
                            store.set_claimed_reward(claimed_reward);

                            let reward_id = *level_config.premium_rewards.at(0);
                            self
                                .emit(
                                    RewardClaimed {
                                        player: address,
                                        season_id,
                                        level,
                                        is_premium: true,
                                        reward_id,
                                    },
                                );
                        }
                    }
                }

                level += 1;
            }
        }

        fn get_claimable_rewards(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> (Span<u32>, Span<u32>) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let progress = store.get_season_progress(address, season_id);

            let mut free_levels = array![];
            let mut premium_levels = array![];

            let mut level = 1;
            loop {
                if level > progress.level {
                    break;
                }

                // Check free rewards
                let claimed_free = store.get_claimed_reward(address, season_id, level, false);
                if claimed_free.address.is_zero() {
                    let level_config = store.get_season_level_config(season_id, level);
                    if level_config.free_rewards.len() > 0 {
                        free_levels.append(level);
                    }
                }

                // Check premium rewards if has season pass
                if progress.has_season_pass {
                    let claimed_premium = store.get_claimed_reward(address, season_id, level, true);
                    if claimed_premium.address.is_zero() {
                        let level_config = store.get_season_level_config(season_id, level);
                        if level_config.premium_rewards.len() > 0 {
                            premium_levels.append(level);
                        }
                    }
                }

                level += 1;
            }

            (free_levels.span(), premium_levels.span())
        }

        fn is_reward_claimed(
            self: @ContractState,
            address: ContractAddress,
            season_id: u32,
            level: u32,
            is_premium: bool,
        ) -> bool {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            let claimed = store.get_claimed_reward(address, season_id, level, is_premium);
            !claimed.address.is_zero()
        }

        fn get_user_progress(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> (u256, u32, bool) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            let progress = store.get_season_progress(address, season_id);
            (progress.season_xp, progress.level, progress.has_season_pass)
        }

        fn has_season_pass(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> bool {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            let progress = store.get_season_progress(address, season_id);
            progress.has_season_pass
        }

        fn configure_season_level(
            ref self: ContractState,
            season_id: u32,
            level: u32,
            required_xp: u256,
            free_rewards: Span<u32>,
            premium_rewards: Span<u32>,
        ) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // Verify season exists
            let season = store.get_season(season_id);
            assert(season.id == season_id, 'Season does not exist');

            let config = SeasonLevelConfig {
                season_id, level, required_xp, free_rewards, premium_rewards,
            };

            store.set_season_level_config(config);
        }

        fn initialize_user_progress(
            ref self: ContractState, address: ContractAddress, season_id: u32,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // Verify season exists and is active
            let season = store.get_season(season_id);
            assert(season.is_active, 'Season not active');

            // Check if progress already exists
            let progress = store.get_season_progress(address, season_id);
            if progress.address.is_zero() {
                // Initialize new progress
                let new_progress = SeasonProgress {
                    address,
                    season_id,
                    season_xp: 0,
                    has_season_pass: false,
                    tier: 1,
                    level: 0,
                };
                store.set_season_progress(new_progress);

                self.emit(UserProgressInitialized { player: address, season_id });
            }
        }

        fn set_season_level_config(ref self: ContractState, config: SeasonLevelConfig) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            StoreTrait::set_season_level_config(ref store, config);
        }

        fn set_mission_xp_config(ref self: ContractState, config: MissionXPConfig) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            StoreTrait::set_mission_xp_config(ref store, config);
        }

        fn set_level_xp_config(ref self: ContractState, config: LevelXPConfig) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            StoreTrait::set_level_xp_config(ref store, config);
        }

        fn get_season_level_config_by_level(
            self: @ContractState, season_id: u32, level: u32,
        ) -> SeasonLevelConfig {
            let mut store = StoreTrait::new(self.world_default());
            store.get_season_level_config(season_id, level)
        }

        fn get_season_level_config_by_address(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> SeasonLevelConfig {
            let mut store = StoreTrait::new(self.world_default());
            let season_progress = store.get_season_progress(address, season_id);
            store.get_season_level_config(season_id, season_progress.level)
        }

        fn setup_default_season_config(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());

            // Set season level configs based on sistema_xp.md
            // Leveles 1-11 - Casual (Tier 1)
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 1,
                    required_xp: 25,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 2,
                    required_xp: 50,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 3,
                    required_xp: 75,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 4,
                    required_xp: 100,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 5,
                    required_xp: 150,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 6,
                    required_xp: 200,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 7,
                    required_xp: 300,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 8,
                    required_xp: 400,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 9,
                    required_xp: 500,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 10,
                    required_xp: 600,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 11,
                    required_xp: 700,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            // Leveles 12-25 - Average (Tier 2)
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 12,
                    required_xp: 800,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 13,
                    required_xp: 900,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 14,
                    required_xp: 1000,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 15,
                    required_xp: 1100,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 16,
                    required_xp: 1200,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 17,
                    required_xp: 1300,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 18,
                    required_xp: 1400,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 19,
                    required_xp: 1500,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 20,
                    required_xp: 1600,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 21,
                    required_xp: 1700,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 22,
                    required_xp: 1800,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 23,
                    required_xp: 1900,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 24,
                    required_xp: 2000,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 25,
                    required_xp: 2100,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            // Leveles 26-32 - Hardcore (Tier 3)
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 26,
                    required_xp: 2200,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 27,
                    required_xp: 2300,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 28,
                    required_xp: 2400,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 29,
                    required_xp: 2500,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 30,
                    required_xp: 2750,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 31,
                    required_xp: 3000,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 32,
                    required_xp: 3500,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            // Leveles 33+ - Legend (Tier 4)
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 33,
                    required_xp: 4000,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
            StoreTrait::set_season_level_config(
                ref store,
                SeasonLevelConfig {
                    season_id,
                    level: 34,
                    required_xp: 5000,
                    free_rewards: [].span(),
                    premium_rewards: [].span(),
                },
            );
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"jokers_of_neon_profile")
        }

        fn _grant_rewards(
            ref self: ContractState, ref store: Store, address: ContractAddress, rewards: Span<u32>,
        ) {
            // This is where you would implement the actual reward granting logic
            // For example, adding items to inventory, granting currency, etc.
            // For now, we just acknowledge that rewards should be granted

            let mut i = 0;
            loop {
                if i >= rewards.len() {
                    break;
                }

                let reward_id = *rewards.at(i);
                let _reward = store.get_season_reward(reward_id);

                // TODO: Implement actual reward granting based on reward_type
                // match reward.reward_type {
                //     RewardType::Item => { /* grant item */ },
                //     RewardType::Currency => { /* grant currency */ },
                //     RewardType::Badge => { /* grant badge */ },
                //     RewardType::Avatar => { /* grant avatar */ },
                // }

                i += 1;
            }
        }

        fn _grant_retroactive_premium_rewards(
            ref self: ContractState,
            ref store: Store,
            address: ContractAddress,
            season_id: u32,
            current_level: u32,
        ) {
            // Grant all premium rewards for levels already reached
            let mut level = 1;
            loop {
                if level > current_level {
                    break;
                }

                // Check if premium reward is already claimed
                let claimed = store.get_claimed_reward(address, season_id, level, true);
                if claimed.address.is_zero() {
                    let level_config = store.get_season_level_config(season_id, level);
                    if level_config.premium_rewards.len() > 0 {
                        self._grant_rewards(ref store, address, level_config.premium_rewards);

                        // Mark as claimed
                        let claimed_reward = ClaimedReward {
                            address,
                            season_id,
                            level,
                            is_premium: true,
                            claimed_at: get_block_timestamp()
                        };
                        store.set_claimed_reward(claimed_reward);

                        let reward_id = *level_config.premium_rewards.at(0);
                        self
                            .emit(
                                RewardClaimed {
                                    player: address,
                                    season_id,
                                    level,
                                    is_premium: true,
                                    reward_id,
                                },
                            );
                    }
                }

                level += 1;
            }
        }
    }
}
