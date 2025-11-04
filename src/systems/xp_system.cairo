use starknet::ContractAddress;
use crate::models::MissionDifficulty;

#[starknet::interface]
pub trait IXPSystem<T> {
    fn add_daily_mission_xp(ref self: T, address: ContractAddress, mission_type: MissionDifficulty);
    fn add_level_completion_xp(ref self: T, address: ContractAddress, level: u32);

    // Configuration methods
    fn setup_default_profile_config(ref self: T);

    // Test method to add XP directly
    fn test_xp(
        ref self: T, address: ContractAddress, season_id: u32, season_xp: u256, profile_xp: u256,
    );
}

#[dojo::contract]
pub mod xp_system {
    use jokers_of_neon_lib::models::external::profile::ProfileLevelConfig;
    use starknet::ContractAddress;
    use crate::constants::constants::DEFAULT_NS_BYTE;
    use crate::models::{MissionDifficulty, SeasonProgress};
    use crate::store::{Store, StoreTrait};
    use crate::utils::utils::{
        get_current_day, get_level_xp_configurable, get_mission_xp_configurable,
    };
    use super::IXPSystem;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
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

    fn dojo_init(
        ref self: ContractState, owner: ContractAddress,
    ) { // self.accesscontrol.initializer();
    // self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, owner);
    // self.accesscontrol._grant_role(WRITER_ROLE, owner);
    }

    #[abi(embed_v0)]
    impl XPSystemImpl of IXPSystem<ContractState> {
        fn add_daily_mission_xp(
            ref self: ContractState, address: ContractAddress, mission_type: MissionDifficulty,
        ) {
            // self.accesscontrol.assert_only_role(WRITER_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // TODO: Validate that the season is active
            let season_id = 1;
            let season_config = store.get_season_config(season_id);
            // assert(season_config.is_active, 'Season is not active');

            let current_day = get_current_day();
            let mut daily_progress = store.get_daily_progress(address, current_day);

            let completion_count = match mission_type {
                MissionDifficulty::Easy => daily_progress.easy_missions,
                MissionDifficulty::Medium => daily_progress.medium_missions,
                MissionDifficulty::Hard => daily_progress.hard_missions,
            };

            let xp_earned = get_mission_xp_configurable(
                world, season_id, mission_type, completion_count,
            );

            if xp_earned > 0 {
                match mission_type {
                    MissionDifficulty::Easy => daily_progress.easy_missions += 1,
                    MissionDifficulty::Medium => daily_progress.medium_missions += 1,
                    MissionDifficulty::Hard => daily_progress.hard_missions += 1,
                }

                daily_progress.daily_xp += xp_earned;
                store.set_daily_progress(daily_progress);

                self._add_profile_xp(ref store, address, xp_earned.into());

                if season_config.is_active {
                    self._add_season_xp(ref store, address, season_id, xp_earned.into());
                }

                self
                    .emit(
                        MissionXPAdded {
                            player: address, season_id, mission_type, xp_earned, day: current_day,
                        },
                    );
            }
        }

        fn add_level_completion_xp(ref self: ContractState, address: ContractAddress, level: u32) {
            // self.accesscontrol.assert_only_role(WRITER_ROLE);

            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // TODO: Validate that the season is active
            let season_id = 1;
            let season_config = store.get_season_config(season_id);
            // assert(season_config.is_active, 'Season is not active');

            let current_day = get_current_day();
            let mut daily_progress = store.get_daily_progress(address, current_day);

            let level_completions_len = daily_progress.level_completions.len();
            let completion_count = if level > 0 && level <= level_completions_len {
                *daily_progress.level_completions.at(level - 1)
            } else {
                0
            };

            let xp_earned = get_level_xp_configurable(world, season_id, level, completion_count);

            if xp_earned > 0 {
                if level > 0 {
                    let mut level_completions = array![];
                    let current_completions = daily_progress.level_completions;
                    let mut i = 0;

                    // Copy existing completions and increment the target level
                    while i < current_completions.len() {
                        if i == level - 1 {
                            level_completions.append(*current_completions.at(i) + 1);
                        } else {
                            level_completions.append(*current_completions.at(i));
                        }
                        i += 1;
                    }

                    // If the level is beyond current array size, extend the array
                    while level_completions.len() < level {
                        if level_completions.len() == level - 1 {
                            level_completions.append(1);
                        } else {
                            level_completions.append(0);
                        }
                    }

                    daily_progress.level_completions = level_completions.span();
                }

                daily_progress.daily_xp += xp_earned;
                store.set_daily_progress(daily_progress);

                self._add_profile_xp(ref store, address, xp_earned.into());

                if season_config.is_active {
                    self._add_season_xp(ref store, address, season_id, xp_earned.into());
                }

                self
                    .emit(
                        LevelXPAdded {
                            player: address, season_id, level, xp_earned, day: current_day,
                        },
                    );
            }
        }

        fn setup_default_profile_config(ref self: ContractState) {
            // self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());

            // Set profile level configs with exponential XP requirements
            let mut level = 1;
            loop {
                if level > 100 {
                    break;
                }

                let required_xp = if level == 1 {
                    100
                } else if level <= 10 {
                    level * level * 50
                } else if level <= 25 {
                    level * level * 75
                } else if level <= 50 {
                    level * level * 100
                } else {
                    level * level * 150
                };

                store
                    .set_profile_level_config(
                        ProfileLevelConfig { level, required_xp: required_xp.into() },
                    );

                level += 1;
            }
        }

        fn test_xp(
            ref self: ContractState,
            address: ContractAddress,
            season_id: u32,
            season_xp: u256,
            profile_xp: u256,
        ) {
            // self.accesscontrol.assert_only_role(WRITER_ROLE);
            let world = self.world_default();
            let mut store = StoreTrait::new(world);

            // Add profile XP if provided
            if profile_xp > 0 {
                self._add_profile_xp(ref store, address, profile_xp);
            }

            // Add season XP if provided
            if season_xp > 0 {
                self._add_season_xp(ref store, address, season_id, season_xp);
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@DEFAULT_NS_BYTE())
        }

        fn _add_profile_xp(
            ref self: ContractState, ref store: Store, address: ContractAddress, xp: u256,
        ) {
            let mut profile = store.get_profile(address);
            let old_level = profile.level;

            // Add to both total XP and current XP
            profile.total_xp += xp;
            profile.xp += xp;

            // Check if player leveled up
            let mut new_level = old_level;
            let mut level_to_check = old_level + 1;

            loop {
                let level_config = store.get_profile_level_config(level_to_check);
                if profile.total_xp >= level_config.required_xp {
                    new_level = level_to_check;
                    level_to_check += 1;
                } else {
                    break;
                }

                // Safety check to prevent infinite loop
                if level_to_check > 100 {
                    break;
                }
            }

            if new_level > old_level {
                profile.level = new_level;

                // Calculate current XP for new level
                // Current XP = total XP - required XP for current level
                let current_level_config = store.get_profile_level_config(new_level);
                profile.xp = profile.total_xp - current_level_config.required_xp;
            }

            store.set_profile(profile);
        }

        fn _add_season_xp(
            ref self: ContractState,
            ref store: Store,
            address: ContractAddress,
            season_id: u32,
            xp: u256,
        ) {
            let mut season_progress = store.get_season_progress(address, season_id);
            let old_level = season_progress.level;

            // Add to season XP
            season_progress.season_xp += xp;

            // Check if player leveled up in the season
            let mut new_level = old_level;
            let mut level_to_check = old_level + 1;

            loop {
                let level_config = store.get_season_level_config(season_id, level_to_check);

                // If level config doesn't exist (required_xp is 0), we've reached the max level
                if level_config.required_xp == 0 {
                    break;
                }

                if season_progress.season_xp >= level_config.required_xp {
                    new_level = level_to_check;
                    level_to_check += 1;
                } else {
                    break;
                }

                // Safety check to prevent infinite loop (max 100 levels)
                if level_to_check > 100 {
                    break;
                }
            }

            // Update level if changed
            if new_level > old_level {
                season_progress.level = new_level;
            }

            // Create updated season progress
            let updated_progress = SeasonProgress {
                address: season_progress.address,
                season_id: season_progress.season_id,
                season_xp: season_progress.season_xp,
                has_season_pass: season_progress.has_season_pass,
                claimable_rewards_id: array![].span(),
                season_pass_unlocked_at_level: season_progress.season_pass_unlocked_at_level,
                level: new_level,
            };

            store.set_season_progress(updated_progress);
        }
    }
}
