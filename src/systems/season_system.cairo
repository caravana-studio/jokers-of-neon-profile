use starknet::ContractAddress;
use crate::models::{
    LevelXPConfig, MissionXPConfig, SeasonConfig, SeasonData, SeasonLevelConfig, SeasonProgress,
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

    fn get_season_progress(
        self: @T, player_address: ContractAddress, season_id: u32,
    ) -> SeasonProgress;
    fn has_season_pass(self: @T, address: ContractAddress, season_id: u32) -> bool;

    // Season configuration methods
    fn set_season_level_config(ref self: T, config: SeasonLevelConfig);
    // TODO: These methods are no longer used. Config is now in constants/season_configs.cairo.
    fn set_mission_xp_config(ref self: T, config: MissionXPConfig);
    fn set_level_xp_config(ref self: T, config: LevelXPConfig);
    fn setup_default_season_config(ref self: T, season_id: u32);
    fn get_season_level_config_by_level(self: @T, season_id: u32, level: u32) -> SeasonLevelConfig;
    fn get_season_level_config_by_address(
        self: @T, address: ContractAddress, season_id: u32,
    ) -> SeasonLevelConfig;

    // Claim rewards
    fn claim_season_rewards(
        ref self: T, address: ContractAddress, season_id: u32, level: u32, is_premium: bool,
    );

    fn get_season_rewards(self: @T, season_id: u32, level: u32, is_premium: bool) -> Span<u32>;

    // Get season line data for frontend
    fn get_season_line(
        self: @T, player: ContractAddress, season_id: u32, max_level: u32,
    ) -> Array<SeasonData>;

    fn remove_tournament_ticket(ref self: T, address: ContractAddress, season_id: u32);
}

#[dojo::contract]
pub mod season_system {
    use dojo::world::WorldStorage;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::constants::constants::{DEFAULT_NS_BYTE, TOURNAMENT_TICKET_REWARD_ID};
    use crate::constants::season_configs::get_season_level_data;
    use crate::models::{
        LevelXPConfig, MissionXPConfig, SeasonConfig, SeasonData, SeasonLevelConfig, SeasonProgress,
    };
    use crate::store::{Store, StoreTrait};
    use crate::systems::permission_system::IPermissionSystemDispatcherTrait;
    use crate::utils::systems::SystemsTrait;
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

    #[abi(embed_v0)]
    impl SeasonSystemImpl of ISeasonSystem<ContractState> {
        fn create_season(ref self: ContractState, season_id: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let season_config = SeasonConfig { season_id, is_active: true };
            store.set_season_config(season_config);
            self.emit(SeasonCreated { season_id });
        }

        fn activate_season(ref self: ContractState, season_id: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let season_config = store.get_season_config(season_id);
            assert(!season_config.is_active, 'Season already active');

            let updated_config = SeasonConfig { season_id, is_active: true };
            store.set_season_config(updated_config);

            self.emit(SeasonActivated { season_id });
        }

        fn deactivate_season(ref self: ContractState, season_id: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

            let updated_config = SeasonConfig { season_id, is_active: false };
            store.set_season_config(updated_config);

            self.emit(SeasonDeactivated { season_id });
        }

        fn get_season_config(self: @ContractState, season_id: u32) -> SeasonConfig {
            let mut store = self.create_store();
            store.get_season_config(season_id)
        }

        fn purchase_season_pass(ref self: ContractState, address: ContractAddress, season_id: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

            let mut progress = store.get_season_progress(address, season_id);
            assert(!progress.has_season_pass, 'Already has season pass');

            progress.has_season_pass = true;
            // TODO: This is for retroactive rewards
            progress.season_pass_unlocked_at_level = 0;
            store.set_season_progress(@progress);

            self.emit(SeasonPassPurchased { player: address, season_id });
        }

        fn get_season_progress(
            self: @ContractState, player_address: ContractAddress, season_id: u32,
        ) -> SeasonProgress {
            let mut store = self.create_store();
            store.get_season_progress(player_address, season_id)
        }

        fn has_season_pass(self: @ContractState, address: ContractAddress, season_id: u32) -> bool {
            let mut store = self.create_store();
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
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            // Verify season exists
            let season_config = store.get_season_config(season_id);
            assert(season_config.season_id == season_id, 'Season does not exist');

            let config = SeasonLevelConfig {
                season_id, level, required_xp, free_rewards, premium_rewards,
            };

            store.set_season_level_config(config);
        }

        fn set_season_level_config(
            ref self: ContractState, config: SeasonLevelConfig,
        ) { // TODO: No longer used. Config is now in constants/season_configs.cairo.
        }

        // TODO: No longer used. Config is now in constants/season_configs.cairo.
        fn set_mission_xp_config(ref self: ContractState, config: MissionXPConfig) {}
        fn set_level_xp_config(ref self: ContractState, config: LevelXPConfig) {}
        fn setup_default_season_config(ref self: ContractState, season_id: u32) {}

        fn get_season_level_config_by_level(
            self: @ContractState, season_id: u32, level: u32,
        ) -> SeasonLevelConfig {
            get_season_level_data(season_id, level)
        }

        fn get_season_level_config_by_address(
            self: @ContractState, address: ContractAddress, season_id: u32,
        ) -> SeasonLevelConfig {
            let mut store = self.create_store();
            let season_progress = store.get_season_progress(address, season_id);
            get_season_level_data(season_id, season_progress.level)
        }

        fn claim_season_rewards(
            ref self: ContractState,
            address: ContractAddress,
            season_id: u32,
            level: u32,
            is_premium: bool,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            // Verify season exists and is active
            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season not active');

            // Get player's season progress
            let season_progress = store.get_season_progress(address, season_id);
            assert(season_progress.level >= level, 'Level not reached');

            // Get level configuration
            let level_data = get_season_level_data(season_id, level);

            // Get or create claim record
            let mut claim_record = store.get_season_reward_claim(address, season_id, level);

            // Get rewards before they're consumed
            let free_rewards = level_data.free_rewards;
            let free_rewards_count = free_rewards.len();
            let premium_rewards = level_data.premium_rewards;
            let premium_rewards_count = premium_rewards.len();
            let mut tickets_earned = 0;

            if is_premium {
                assert(season_progress.has_season_pass, 'No season pass');
                assert(
                    level >= season_progress.season_pass_unlocked_at_level,
                    'Level before season pass',
                );
                assert(!claim_record.premium_claimed, 'Premium already claimed');
                assert(premium_rewards_count > 0, 'No premium rewards');

                for reward_id in premium_rewards {
                    if *reward_id == TOURNAMENT_TICKET_REWARD_ID {
                        tickets_earned += 1;
                    }
                }
                claim_record.premium_claimed = true;
            } else {
                for reward_id in free_rewards {
                    if *reward_id == TOURNAMENT_TICKET_REWARD_ID {
                        tickets_earned += 1;
                    }
                }
                assert(!claim_record.free_claimed, 'Free already claimed');
                assert(free_rewards_count > 0, 'No free rewards');
                claim_record.free_claimed = true;
            }

            if tickets_earned > 0 {
                let mut progress = store.get_season_progress(address, season_id);
                progress.tournament_ticket += tickets_earned;
                store.set_season_progress(@progress);
            }

            claim_record.player = address;
            claim_record.season_id = season_id;
            claim_record.level = level;
            store.set_season_reward_claim(claim_record);
        }

        fn get_season_rewards(
            self: @ContractState, season_id: u32, level: u32, is_premium: bool,
        ) -> Span<u32> {
            // Get level configuration
            let level_data = get_season_level_data(season_id, level);
            let free_rewards = level_data.free_rewards;
            let premium_rewards = level_data.premium_rewards;
            let mut rewards = array![];

            if is_premium {
                for reward_id in premium_rewards {
                    rewards.append(*reward_id);
                }
            } else {
                for reward_id in free_rewards {
                    rewards.append(*reward_id);
                }
            }
            rewards.span()
        }

        // NOTE: Season configs are now defined as pure functions in constants/season_configs.cairo.
        // No need to call setup_default_season_config after deploy anymore.

        fn get_season_line(
            self: @ContractState, player: ContractAddress, season_id: u32, max_level: u32,
        ) -> Array<SeasonData> {
            let mut store = self.create_store();
            let mut result: Array<SeasonData> = array![];

            let mut current_level: u32 = 1;
            loop {
                if current_level > max_level {
                    break;
                }

                // Get level config
                let level_data = get_season_level_data(season_id, current_level);

                // Get claim status for this level
                let claim_record = store.get_season_reward_claim(player, season_id, current_level);

                // Build SeasonData
                let season_data = SeasonData {
                    level: current_level,
                    required_xp: level_data.required_xp,
                    free_rewards: level_data.free_rewards,
                    premium_rewards: level_data.premium_rewards,
                    free_claimed: claim_record.free_claimed,
                    premium_claimed: claim_record.premium_claimed,
                };

                result.append(season_data);
                current_level += 1;
            }
            result
        }

        fn remove_tournament_ticket(
            ref self: ContractState, address: ContractAddress, season_id: u32,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let mut progress = store.get_season_progress(address, season_id);
            assert(progress.tournament_ticket > 0, 'No tournament tickets available');
            progress.tournament_ticket -= 1;
            store.set_season_progress(@progress);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn create_store(self: @ContractState) -> Store {
            StoreTrait::new(self.create_world())
        }

        fn create_world(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS_BYTE())
        }
    }
}
