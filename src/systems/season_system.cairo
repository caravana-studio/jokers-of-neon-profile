use starknet::ContractAddress;
use crate::models::{
    LevelXPConfig, MissionXPConfig, SeasonConfig, SeasonLevelConfig, SeasonProgress,
};

#[starknet::interface]
pub trait ISeasonSystem<T> {
    // Season management
    fn create_season(ref self: T, season_id: u32);
    fn activate_season(ref self: T, season_id: u32);
    fn deactivate_season(ref self: T, season_id: u32);
    fn get_season_config(self: @T, season_id: u32) -> SeasonConfig;

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

    // User initialization
    fn initialize_user_progress(ref self: T, address: ContractAddress, season_id: u32);

    fn get_season_progress(
        self: @T, player_address: ContractAddress, season_id: u32,
    ) -> SeasonProgress;
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

    // Claim rewards
    fn claim_season_rewards(ref self: T, address: ContractAddress, season_id: u32, level: u32);
}

#[dojo::contract]
pub mod season_system {
    use core::num::traits::Zero;
    use dojo::event::EventStorage;
    use jokers_of_neon_lib::random::RandomTrait;
    use starknet::ContractAddress;
    use crate::constants::constants::MOD_ID;
    use crate::models::{
        CardMintedEvent, ItemType, LevelXPConfig, MissionXPConfig, SeasonConfig, SeasonLevelConfig,
        SeasonProgress,
    };
    use crate::store::StoreTrait;
    use crate::systems::pack_system::{
        INFTCardSystemDispatcher, INFTCardSystemDispatcherTrait, IPackSystemDispatcher,
        IPackSystemDispatcherTrait,
    };
    use crate::utils::pack::PackTrait;
    use super::ISeasonSystem;


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SeasonCreated: SeasonCreated,
        SeasonActivated: SeasonActivated,
        SeasonDeactivated: SeasonDeactivated,
        SeasonPassPurchased: SeasonPassPurchased,
        PacksGranted: PacksGranted,
        PackOpened: PackOpened,
        SeasonLevelReached: SeasonLevelReached,
        UserProgressInitialized: UserProgressInitialized,
        RewardsClaimed: RewardsClaimed,
    }

    #[derive(Drop, starknet::Event)]
    struct SeasonCreated {
        #[key]
        season_id: u32,
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
    struct SeasonPassPurchased {
        #[key]
        player: ContractAddress,
        season_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct PacksGranted {
        #[key]
        player: ContractAddress,
        season_id: u32,
        level: u32,
        is_premium: bool,
        pack_count: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct PackOpened {
        #[key]
        player: ContractAddress,
        season_id: u32,
        pack_id: u32,
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

    #[derive(Drop, starknet::Event)]
    struct RewardsClaimed {
        #[key]
        player: ContractAddress,
        season_id: u32,
        level: u32,
        is_premium: bool,
        pack_count: u32,
    }

    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");

    fn dojo_init(ref self: ContractState, owner: ContractAddress) {}

    #[abi(embed_v0)]
    impl SeasonSystemImpl of ISeasonSystem<ContractState> {
        fn create_season(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season_config = SeasonConfig { season_id, is_active: true };

            store.set_season_config(season_config);

            self.emit(SeasonCreated { season_id });
        }

        fn activate_season(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season_config = store.get_season_config(season_id);
            assert(!season_config.is_active, 'Season already active');

            let updated_config = SeasonConfig { season_id, is_active: true };
            store.set_season_config(updated_config);

            self.emit(SeasonActivated { season_id });
        }

        fn deactivate_season(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

            let updated_config = SeasonConfig { season_id, is_active: false };
            store.set_season_config(updated_config);

            self.emit(SeasonDeactivated { season_id });
        }

        fn get_season_config(self: @ContractState, season_id: u32) -> SeasonConfig {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            store.get_season_config(season_id)
        }

        fn purchase_season_pass(ref self: ContractState, address: ContractAddress, season_id: u32) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

            let mut progress = store.get_season_progress(address, season_id);
            assert(!progress.has_season_pass, 'Already has season pass');

            progress.has_season_pass = true;
            store.set_season_progress(progress);

            self.emit(SeasonPassPurchased { player: address, season_id });
        }

        fn get_season_progress(
            self: @ContractState, player_address: ContractAddress, season_id: u32,
        ) -> SeasonProgress {
            let mut store = StoreTrait::new(self.world_default());
            store.get_season_progress(player_address, season_id)
        }

        fn has_season_pass(self: @ContractState, address: ContractAddress, season_id: u32) -> bool {
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
            let season_config = store.get_season_config(season_id);
            assert(season_config.season_id == season_id, 'Season does not exist');

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
            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

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
                    claimable_rewards_id: [].span(),
                };
                store.set_season_progress(new_progress);

                self.emit(UserProgressInitialized { player: address, season_id });
            }
        }

        fn set_season_level_config(ref self: ContractState, config: SeasonLevelConfig) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_season_level_config(config);
        }

        fn set_mission_xp_config(ref self: ContractState, config: MissionXPConfig) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_mission_xp_config(config);
        }

        fn set_level_xp_config(ref self: ContractState, config: LevelXPConfig) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_level_xp_config(config);
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

        fn claim_season_rewards(
            ref self: ContractState, address: ContractAddress, season_id: u32, level: u32,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // Verify season exists and is active
            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

            // Get player's season progress
            let season_progress = store.get_season_progress(address, season_id);
            assert(season_progress.level >= level, 'Level not reached');

            // Get level configuration
            let level_config = store.get_season_level_config(season_id, level);

            // Get or create claim record
            let mut claim_record = store.get_season_reward_claim(address, season_id, level);

            // Check if has season pass
            let has_season_pass = season_progress.has_season_pass;

            // Get rewards before they're consumed
            let free_rewards = level_config.free_rewards;
            let free_rewards_count = free_rewards.len();
            let premium_rewards = level_config.premium_rewards;
            let premium_rewards_count = premium_rewards.len();

            // Claim free rewards if not already claimed
            if !claim_record.free_claimed && free_rewards_count > 0 {
                // Mint each pack in free_rewards
                for pack_id in free_rewards {
                    self.mint_pack(address, *pack_id);
                }

                claim_record.free_claimed = true;

                self
                    .emit(
                        RewardsClaimed {
                            player: address,
                            season_id,
                            level,
                            is_premium: false,
                            pack_count: free_rewards_count,
                        },
                    );
            }

            // Claim premium rewards if has season pass and not already claimed
            if has_season_pass && !claim_record.premium_claimed && premium_rewards_count > 0 {
                // Mint each pack in premium_rewards
                for pack_id in premium_rewards {
                    self.mint_pack(address, *pack_id);
                }

                claim_record.premium_claimed = true;

                self
                    .emit(
                        RewardsClaimed {
                            player: address,
                            season_id,
                            level,
                            is_premium: true,
                            pack_count: premium_rewards_count,
                        },
                    );
            }

            // Update claim record
            claim_record.player = address;
            claim_record.season_id = season_id;
            claim_record.level = level;
            store.set_season_reward_claim(claim_record);
        }

        fn setup_default_season_config(ref self: ContractState, season_id: u32) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());

            // Set season level configs based on sistema_xp.md
            // Leveles 1-11 - Casual (Tier 1)
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 1,
                        required_xp: 25,
                        free_rewards: [1].span(), // TODO: 
                        premium_rewards: [2].span() // TODO:
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 2,
                        required_xp: 50,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 3,
                        required_xp: 75,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 4,
                        required_xp: 100,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 5,
                        required_xp: 150,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 6,
                        required_xp: 200,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 7,
                        required_xp: 300,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 8,
                        required_xp: 400,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 9,
                        required_xp: 500,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 10,
                        required_xp: 600,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 11,
                        required_xp: 700,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            // Leveles 12-25 - Average (Tier 2)
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 12,
                        required_xp: 800,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 13,
                        required_xp: 900,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 14,
                        required_xp: 1000,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 15,
                        required_xp: 1100,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 16,
                        required_xp: 1200,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 17,
                        required_xp: 1300,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 18,
                        required_xp: 1400,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 19,
                        required_xp: 1500,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 20,
                        required_xp: 1600,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 21,
                        required_xp: 1700,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 22,
                        required_xp: 1800,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 23,
                        required_xp: 1900,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 24,
                        required_xp: 2000,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 25,
                        required_xp: 2100,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            // Leveles 26-32 - Hardcore (Tier 3)
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 26,
                        required_xp: 2200,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 27,
                        required_xp: 2300,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 28,
                        required_xp: 2400,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 29,
                        required_xp: 2500,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 30,
                        required_xp: 2750,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 31,
                        required_xp: 3000,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 32,
                        required_xp: 3500,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            // Leveles 33+ - Legend (Tier 4)
            store
                .set_season_level_config(
                    SeasonLevelConfig {
                        season_id,
                        level: 33,
                        required_xp: 4000,
                        free_rewards: [].span(),
                        premium_rewards: [].span(),
                    },
                );
            store
                .set_season_level_config(
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

        fn mint_pack(world: WorldStorage, recipient: ContractAddress, pack_id: u32) {
            match world.dns(@"pack_system") {
                Option::Some((
                    contract_address, _,
                )) => { IPackSystemDispatcher { contract_address } },
                Option::None => {
                    panic!(
                        "[SystemsTrait] - dns Season System doesnt exists on world `{}`",
                        world.namespace_hash,
                    )
                },
            }.mint(recipient, pack_id)
        }
    }
}
