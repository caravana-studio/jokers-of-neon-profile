use starknet::ContractAddress;
use crate::models::{Season, SeasonLevelConfig, MissionXPConfig, LevelXPConfig, SeasonProgress};

#[starknet::interface]
pub trait ISeasonSystem<T> {
    // Season management
    fn create_season(
        ref self: T, id: u32, name: ByteArray, start_date: u64, end_date: u64,
    ) -> Season;
    fn activate_season(ref self: T, season_id: u32);
    fn deactivate_season(ref self: T, season_id: u32);
    fn get_season(self: @T, season_id: u32) -> Season;

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

    // View methods
    fn get_user_progress(
        self: @T, address: ContractAddress, season_id: u32,
    ) -> (u256, u32, bool); // (xp, level, has_pass)
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

    // Get pending packs for a player
    fn get_pending_packs(self: @T, address: ContractAddress) -> Span<u32>;
}

#[dojo::contract]
pub mod season_system {
    use core::num::traits::Zero;
    use starknet::ContractAddress;
    use crate::models::{
        PendingPacks, Season, SeasonLevelConfig, SeasonProgress, MissionXPConfig, LevelXPConfig,
    };
    use crate::store::{Store, StoreTrait};
    use super::ISeasonSystem;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SeasonCreated: SeasonCreated,
        SeasonActivated: SeasonActivated,
        SeasonDeactivated: SeasonDeactivated,
        SeasonPassPurchased: SeasonPassPurchased,
        PacksGranted: PacksGranted,
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

        fn purchase_season_pass(
            ref self: ContractState, address: ContractAddress, season_id: u32,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            let season = StoreTrait::get_season(ref store, season_id);
            assert(season.is_active, 'Season not active');

            let mut progress = StoreTrait::get_season_progress(ref store, address, season_id);
            assert(!progress.has_season_pass, 'Already has season pass');

            progress.has_season_pass = true;
            StoreTrait::set_season_progress(ref store, progress);

            self.emit(SeasonPassPurchased { player: address, season_id });
        }

        fn get_user_progress(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> (u256, u32, bool) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            let progress = StoreTrait::get_season_progress(ref store, address, season_id);
            (progress.season_xp, progress.level, progress.has_season_pass)
        }

        fn get_season_progress(
            self: @ContractState, player_address: ContractAddress, season_id: u32,
        ) -> SeasonProgress {
            let mut store = StoreTrait::new(self.world_default());
            StoreTrait::get_season_progress(ref store, player_address, season_id)
        }

        fn has_season_pass(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> bool {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            let progress = StoreTrait::get_season_progress(ref store, address, season_id);
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
            let season = StoreTrait::get_season(ref store, season_id);
            assert(season.id == season_id, 'Season does not exist');

            let config = SeasonLevelConfig {
                season_id, level, required_xp, free_rewards, premium_rewards,
            };

            StoreTrait::set_season_level_config(ref store, config);
        }

        fn initialize_user_progress(
            ref self: ContractState, address: ContractAddress, season_id: u32,
        ) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // Verify season exists and is active
            let season = StoreTrait::get_season(ref store, season_id);
            assert(season.is_active, 'Season not active');

            // Check if progress already exists
            let progress = StoreTrait::get_season_progress(ref store, address, season_id);
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
                StoreTrait::set_season_progress(ref store, new_progress);

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
            StoreTrait::get_season_level_config(ref store, season_id, level)
        }

        fn get_season_level_config_by_address(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> SeasonLevelConfig {
            let mut store = StoreTrait::new(self.world_default());
            let season_progress = StoreTrait::get_season_progress(ref store, address, season_id);
            StoreTrait::get_season_level_config(ref store, season_id, season_progress.level)
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

        fn get_pending_packs(self: @ContractState, address: ContractAddress) -> Span<u32> {
            let mut store = StoreTrait::new(self.world_default());
            let pending_packs = StoreTrait::get_pending_packs(ref store, address);
            pending_packs.pack_ids.span()
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
            // Get current pending packs for the player
            let mut pending_packs = StoreTrait::get_pending_packs(ref store, address);

            // If this is a new player (no existing record), initialize the array
            let mut pack_list = if pending_packs.address.is_zero() {
                array![]
            } else {
                pending_packs.pack_ids.clone()
            };

            // Add all reward pack IDs to the player's pending packs
            let mut i = 0;
            loop {
                if i >= rewards.len() {
                    break;
                }

                let pack_id = *rewards.at(i);
                pack_list.append(pack_id);

                i += 1;
            }

            // Save the updated pending packs
            let updated_pending_packs = PendingPacks { address, pack_ids: pack_list };
            StoreTrait::set_pending_packs(ref store, updated_pending_packs);
        }
    }
}
