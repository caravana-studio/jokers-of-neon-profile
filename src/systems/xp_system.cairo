use starknet::ContractAddress;
use crate::models::{MissionDifficulty, MissionXPConfig, LevelXPConfig, SeasonConfig, SeasonTierConfig};

#[starknet::interface]
trait IXPSystem<T> {
    fn add_daily_mission_xp(ref self: T, address: ContractAddress, season_id: u32, mission_type: MissionDifficulty);
    fn add_level_completion_xp(ref self: T, address: ContractAddress, season_id: u32, level: u32);
    
    // Configuration methods
    fn set_mission_xp_config(ref self: T, config: MissionXPConfig);
    fn set_level_xp_config(ref self: T, config: LevelXPConfig);
    fn set_season_config(ref self: T, config: SeasonConfig);
    fn set_season_tier_config(ref self: T, config: SeasonTierConfig);
    
    // Setup methods for initializing default configurations
    fn setup_default_season_config(ref self: T, season_id: u32);
}

#[dojo::contract]
pub mod xp_system {
    use super::IXPSystem;
    use crate::{
        models::{MissionDifficulty, MissionXPConfig, LevelXPConfig, SeasonConfig, SeasonTierConfig},
        utils::{get_current_day, get_mission_xp_configurable, get_level_xp_configurable, 
               get_season_tier_configurable},
        store::StoreTrait,
    };
    use starknet::ContractAddress;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;

    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        MissionXPAdded: MissionXPAdded,
        LevelXPAdded: LevelXPAdded,
    }

    #[derive(Drop, starknet::Event)]
    struct MissionXPAdded {
        #[key]
        player: ContractAddress,
        season_id: u32,
        mission_type: MissionDifficulty,
        xp_earned: u32,
        day: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct LevelXPAdded {
        #[key]
        player: ContractAddress,
        season_id: u32,
        level: u32,
        xp_earned: u32,
        day: u64,
    }

    const WRITER_ROLE: felt252 = selector!("WRITER_ROLE");

    fn dojo_init(ref self: ContractState, owner: ContractAddress) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(WRITER_ROLE, owner);
    }

    #[abi(embed_v0)]
    impl XPSystemImpl of IXPSystem<ContractState> {
        fn add_daily_mission_xp(ref self: ContractState, address: ContractAddress, season_id: u32, mission_type: MissionDifficulty) {
            self.accesscontrol.assert_only_role(WRITER_ROLE);
            
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            
            // Validate that the season is active
            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season is not active');
            let current_day = get_current_day();
            let mut daily_progress = store.get_daily_progress(address, current_day);
            
            let completion_count = match mission_type {
                MissionDifficulty::Easy => daily_progress.easy_missions,
                MissionDifficulty::Medium => daily_progress.medium_missions,
                MissionDifficulty::Hard => daily_progress.hard_missions,
            };
            
            let xp_earned = get_mission_xp_configurable(world, season_id, mission_type, completion_count);
            
            if xp_earned > 0 {
                match mission_type {
                    MissionDifficulty::Easy => daily_progress.easy_missions += 1,
                    MissionDifficulty::Medium => daily_progress.medium_missions += 1,
                    MissionDifficulty::Hard => daily_progress.hard_missions += 1,
                };
                
                daily_progress.daily_xp += xp_earned;
                
                store.set_daily_progress(daily_progress);
                
                self._add_season_xp(address, season_id, xp_earned.into());
                
                self.emit(MissionXPAdded {
                    player: address,
                    season_id,
                    mission_type,
                    xp_earned,
                    day: current_day,
                });
            }
        }

        fn add_level_completion_xp(ref self: ContractState, address: ContractAddress, season_id: u32, level: u32) {
            self.accesscontrol.assert_only_role(WRITER_ROLE);
            
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            
            // Validate that the season is active
            let season_config = store.get_season_config(season_id);
            assert(season_config.is_active, 'Season is not active');
            
            let current_day = get_current_day();
            let mut daily_progress = store.get_daily_progress(address, current_day);
            
            let completion_count = if level == 1 {
                daily_progress.level1_completions
            } else if level == 2 {
                daily_progress.level2_completions
            } else if level == 3 {
                daily_progress.level3_completions
            } else if level == 4 {
                daily_progress.level4_completions
            } else if level == 5 {
                daily_progress.level5_completions
            } else {
                return; // Invalid level
            };
            
            let xp_earned = get_level_xp_configurable(world, season_id, level, completion_count);
            
            if xp_earned > 0 {
                if level == 1 {
                    daily_progress.level1_completions += 1;
                } else if level == 2 {
                    daily_progress.level2_completions += 1;
                } else if level == 3 {
                    daily_progress.level3_completions += 1;
                } else if level == 4 {
                    daily_progress.level4_completions += 1;
                } else if level == 5 {
                    daily_progress.level5_completions += 1;
                }
                
                daily_progress.daily_xp += xp_earned;
                
                store.set_daily_progress(daily_progress);
                
                self._add_season_xp(address, season_id, xp_earned.into());
                
                self.emit(LevelXPAdded {
                    player: address,
                    season_id,
                    level,
                    xp_earned,
                    day: current_day,
                });
            }
        }

        fn set_mission_xp_config(ref self: ContractState, config: MissionXPConfig) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_mission_xp_config(config);
        }

        fn set_level_xp_config(ref self: ContractState, config: LevelXPConfig) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_level_xp_config(config);
        }

        fn set_season_config(ref self: ContractState, config: SeasonConfig) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_season_config(config);
        }

        fn set_season_tier_config(ref self: ContractState, config: SeasonTierConfig) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_season_tier_config(config);
        }

        fn setup_default_season_config(ref self: ContractState, season_id: u32) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            
            // Set season config
            store.set_season_config(SeasonConfig {
                season_id,
                is_active: true,
            });

            // Set mission XP configs based on sistema_xp.md
            // Easy missions
            store.set_mission_xp_config(MissionXPConfig { season_id, difficulty: MissionDifficulty::Easy, completion_count: 0, xp_reward: 10 });
            store.set_mission_xp_config(MissionXPConfig { season_id, difficulty: MissionDifficulty::Easy, completion_count: 1, xp_reward: 0 });
            
            // Medium missions  
            store.set_mission_xp_config(MissionXPConfig { season_id, difficulty: MissionDifficulty::Medium, completion_count: 0, xp_reward: 20 });
            store.set_mission_xp_config(MissionXPConfig { season_id, difficulty: MissionDifficulty::Medium, completion_count: 1, xp_reward: 0 });
            
            // Hard missions
            store.set_mission_xp_config(MissionXPConfig { season_id, difficulty: MissionDifficulty::Hard, completion_count: 0, xp_reward: 30 });
            store.set_mission_xp_config(MissionXPConfig { season_id, difficulty: MissionDifficulty::Hard, completion_count: 1, xp_reward: 0 });

            // Set level XP configs
            // Level 1
            store.set_level_xp_config(LevelXPConfig { season_id, level: 1, completion_count: 0, xp_reward: 5 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 1, completion_count: 1, xp_reward: 0 });
            
            // Level 2
            store.set_level_xp_config(LevelXPConfig { season_id, level: 2, completion_count: 0, xp_reward: 10 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 2, completion_count: 1, xp_reward: 0 });
            
            // Level 3
            store.set_level_xp_config(LevelXPConfig { season_id, level: 3, completion_count: 0, xp_reward: 15 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 3, completion_count: 1, xp_reward: 5 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 3, completion_count: 2, xp_reward: 0 });
            
            // Level 4
            store.set_level_xp_config(LevelXPConfig { season_id, level: 4, completion_count: 0, xp_reward: 20 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 4, completion_count: 1, xp_reward: 10 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 4, completion_count: 2, xp_reward: 0 });
            
            // Level 5
            store.set_level_xp_config(LevelXPConfig { season_id, level: 5, completion_count: 0, xp_reward: 25 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 5, completion_count: 1, xp_reward: 15 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 5, completion_count: 2, xp_reward: 5 });
            store.set_level_xp_config(LevelXPConfig { season_id, level: 5, completion_count: 3, xp_reward: 0 });

            // Set season tier configs based on sistema_xp.md
            // Tier 1 - Casual
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 1, required_xp: 25, tier_name: "Casual", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 2, required_xp: 50, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 3, required_xp: 75, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 4, required_xp: 100, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 5, required_xp: 150, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 6, required_xp: 200, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 7, required_xp: 300, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 8, required_xp: 400, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 9, required_xp: 500, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 10, required_xp: 600, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 11, required_xp: 700, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            // Tier 12 - Average
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 12, required_xp: 800, tier_name: "Average", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 13, required_xp: 900, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            // Tier 14 - Tournament pass
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 14, required_xp: 1000, tier_name: "Tournament pass", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 15, required_xp: 1100, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 16, required_xp: 1200, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 17, required_xp: 1300, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 18, required_xp: 1400, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 19, required_xp: 1500, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 20, required_xp: 1600, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 21, required_xp: 1700, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 22, required_xp: 1800, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 23, required_xp: 1900, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 24, required_xp: 2000, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 25, required_xp: 2100, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            // Tier 26 - Hardcore
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 26, required_xp: 2200, tier_name: "Hardcore", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 27, required_xp: 2300, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 28, required_xp: 2400, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 29, required_xp: 2500, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 30, required_xp: 2750, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 31, required_xp: 3000, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 32, required_xp: 3500, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 33, required_xp: 4000, tier_name: "", free_rewards: [].span(), premium_rewards: [].span() });
            // Tier 34 - Legend
            store.set_season_tier_config(SeasonTierConfig { season_id, tier: 34, required_xp: 5000, tier_name: "Legend", free_rewards: [].span(), premium_rewards: [].span() });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"jokers_of_neon_profile")
        }

        fn _add_season_xp(self: @ContractState, address: ContractAddress, season_id: u32, xp: u256) {
            let world = self.world_default();
            let mut store = StoreTrait::new(world);
            let mut profile = store.get_profile(address);
            let mut season_progress = store.get_season_progress(address, season_id);

            profile.xp += xp;
            season_progress.season_xp += xp;
            
            let new_tier = get_season_tier_configurable(world, season_id, season_progress.season_xp);
            if new_tier > season_progress.tier {
                season_progress.tier = new_tier;
            }

            store.set_profile(profile);
            store.set_season_progress(season_progress);
        }
    }
}