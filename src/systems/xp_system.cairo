use starknet::ContractAddress;

#[starknet::interface]
pub trait IXPSystem<T> {
    fn add_daily_mission_xp(ref self: T, address: ContractAddress, mission_type: u8);
    fn add_mission_xp(
        ref self: T,
        address: ContractAddress,
        period_type: u8,
        period_id: u64,
        mission_id: felt252,
        template_id: felt252,
        difficulty: u8,
        xp: u32,
    );
    fn get_streak_status(self: @T, address: ContractAddress) -> crate::models::StreakStatus;
    fn grant_streak_protectors(
        ref self: T, address: ContractAddress, quantity: u16, source: felt252, source_id: felt252,
    );
    fn add_level_completion_xp(ref self: T, address: ContractAddress, level: u32);

    // Configuration methods
    fn setup_default_profile_config(ref self: T);

    // XP Multiplier methods
    fn set_xp_multiplier(ref self: T, multiplier: u32);
    fn get_xp_multiplier(self: @T) -> u32;

    // Test method to add XP directly
    fn test_xp(
        ref self: T, address: ContractAddress, season_id: u32, season_xp: u256, profile_xp: u256,
    );
}

#[dojo::contract]
pub mod xp_system {
    use dojo::world::WorldStorage;
    use jokers_of_neon_lib::models::external::profile::ProfileLevelConfig;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::constants::constants::{
        CURRENT_SEASON_ID, DEFAULT_NS_BYTE, MAX_STREAK_PROTECTORS, MISSION_PERIOD_DAILY,
        MISSION_PERIOD_WEEKLY,
    };
    use crate::constants::season_configs::get_season_level_data;
    use crate::models::{
        MissionXPAward, MissionXPProgress, SeasonProgress, StreakDayCompletion,
        StreakProtectorGrant, StreakStatus, XPMultiplier,
    };
    use crate::store::{Store, StoreTrait};
    use crate::systems::permission_system::IPermissionSystemDispatcherTrait;
    use crate::utils::systems::SystemsTrait;
    use crate::utils::utils::{
        get_current_day, get_level_xp_configurable, get_mission_xp_configurable,
    };
    use super::IXPSystem;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MissionXPAdded: MissionXPAdded,
        MissionXPAddedV2: MissionXPAddedV2,
        DailyStreakUpdated: DailyStreakUpdated,
        StreakProtectorsGranted: StreakProtectorsGranted,
        LevelXPAdded: LevelXPAdded,
    }

    #[derive(Drop, starknet::Event)]
    struct MissionXPAdded {
        #[key]
        player: ContractAddress,
        season_id: u32,
        mission_type: u8,
        xp_earned: u32,
        day: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct MissionXPAddedV2 {
        #[key]
        player: ContractAddress,
        season_id: u32,
        period_type: u8,
        period_id: u64,
        mission_id: felt252,
        template_id: felt252,
        difficulty: u8,
        base_xp: u32,
        xp_earned: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct DailyStreakUpdated {
        #[key]
        player: ContractAddress,
        period_id: u64,
        mission_id: felt252,
        current_streak: u16,
        longest_streak: u16,
        protectors_used: u16,
        protectors_available: u16,
        reset: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct StreakProtectorsGranted {
        #[key]
        player: ContractAddress,
        source: felt252,
        source_id: felt252,
        quantity: u16,
        protectors_available: u16,
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

    #[abi(embed_v0)]
    impl XPSystemImpl of IXPSystem<ContractState> {
        fn add_daily_mission_xp(
            ref self: ContractState, address: ContractAddress, mission_type: u8,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            // TODO: Validate that the season is active
            let season_id = CURRENT_SEASON_ID;
            let season_config = store.get_season_config(season_id);
            // assert(season_config.is_active, 'Season is not active');

            let current_day = get_current_day();
            let mut daily_progress = store.get_daily_progress(address, current_day);

            let completion_count = match mission_type {
                1 => daily_progress.easy_missions,
                2 => daily_progress.medium_missions,
                3 => daily_progress.hard_missions,
                _ => 999,
            };

            let base_xp = get_mission_xp_configurable(season_id, mission_type, completion_count);

            let xp_earned = self._xp_with_multiplier(ref store, base_xp);

            if xp_earned > 0 {
                match mission_type {
                    1 => daily_progress.easy_missions += 1,
                    2 => daily_progress.medium_missions += 1,
                    3 => daily_progress.hard_missions += 1,
                    _ => {},
                }

                daily_progress.daily_xp += xp_earned;
                store.set_daily_progress(daily_progress);

                self._apply_xp(ref store, address, season_id, season_config.is_active, xp_earned);

                self
                    .emit(
                        MissionXPAdded {
                            player: address, season_id, mission_type, xp_earned, day: current_day,
                        },
                    );
            }
        }

        fn add_mission_xp(
            ref self: ContractState,
            address: ContractAddress,
            period_type: u8,
            period_id: u64,
            mission_id: felt252,
            template_id: felt252,
            difficulty: u8,
            xp: u32,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            assert(
                period_type == MISSION_PERIOD_DAILY || period_type == MISSION_PERIOD_WEEKLY,
                'Invalid mission period',
            );
            assert(mission_id != 0, 'Invalid mission id');

            let season_id = CURRENT_SEASON_ID;
            let existing_award = store
                .get_mission_xp_award(address, season_id, period_type, period_id, mission_id);
            if existing_award.completed {
                return;
            }

            let season_config = store.get_season_config(season_id);
            let xp_earned = self._xp_with_multiplier(ref store, xp);
            if xp_earned == 0 {
                return;
            }

            let progress = store
                .get_mission_xp_progress(address, season_id, period_type, period_id);
            let mut easy_missions = progress.easy_missions;
            let mut medium_missions = progress.medium_missions;
            let mut hard_missions = progress.hard_missions;
            match difficulty {
                1 => easy_missions += 1,
                2 => medium_missions += 1,
                3 => hard_missions += 1,
                _ => {},
            }
            store
                .set_mission_xp_progress(
                    MissionXPProgress {
                        address,
                        season_id,
                        period_type,
                        period_id,
                        period_xp: progress.period_xp + xp_earned,
                        easy_missions,
                        medium_missions,
                        hard_missions,
                    },
                );

            store
                .set_mission_xp_award(
                    MissionXPAward {
                        address,
                        season_id,
                        period_type,
                        period_id,
                        mission_id,
                        template_id,
                        difficulty,
                        xp_earned,
                        completed: true,
                    },
                );

            self._apply_xp(ref store, address, season_id, season_config.is_active, xp_earned);

            if period_type == MISSION_PERIOD_DAILY {
                self._apply_daily_streak(ref store, address, period_id, mission_id);
            }

            self
                .emit(
                    MissionXPAddedV2 {
                        player: address,
                        season_id,
                        period_type,
                        period_id,
                        mission_id,
                        template_id,
                        difficulty,
                        base_xp: xp,
                        xp_earned,
                    },
                );
        }

        fn get_streak_status(self: @ContractState, address: ContractAddress) -> StreakStatus {
            let mut store = self.create_store();
            self._streak_status(ref store, address)
        }

        fn grant_streak_protectors(
            ref self: ContractState,
            address: ContractAddress,
            quantity: u16,
            source: felt252,
            source_id: felt252,
        ) {
            assert(quantity > 0, 'Invalid quantity');
            assert(source != 0, 'Invalid source');
            assert(source_id != 0, 'Invalid source id');

            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let existing_grant = store.get_streak_protector_grant(address, source, source_id);
            if existing_grant.claimed {
                return;
            }

            let mut state = store.get_streak_state(address);
            let current_available: u32 = state.protectors_available.into();
            let requested: u32 = quantity.into();
            let max_protectors: u32 = MAX_STREAK_PROTECTORS.into();
            assert(current_available + requested <= max_protectors, 'Protector slots full');
            let next_available = current_available + requested;
            let applied_quantity: u16 = (next_available - current_available).try_into().unwrap();

            state.player = address;
            state.protectors_available = next_available.try_into().unwrap();
            store.set_streak_state(state);
            store
                .set_streak_protector_grant(
                    StreakProtectorGrant {
                        player: address,
                        source,
                        source_id,
                        quantity: applied_quantity,
                        claimed: true,
                    },
                );

            self
                .emit(
                    StreakProtectorsGranted {
                        player: address,
                        source,
                        source_id,
                        quantity: applied_quantity,
                        protectors_available: state.protectors_available,
                    },
                );
        }

        fn add_level_completion_xp(ref self: ContractState, address: ContractAddress, level: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            // TODO: Validate that the season is active
            let season_id = CURRENT_SEASON_ID;
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

            let base_xp = get_level_xp_configurable(season_id, level, completion_count);

            let xp_earned = self._xp_with_multiplier(ref store, base_xp);

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

                self._apply_xp(ref store, address, season_id, season_config.is_active, xp_earned);

                self
                    .emit(
                        LevelXPAdded {
                            player: address, season_id, level, xp_earned, day: current_day,
                        },
                    );
            }
        }

        fn setup_default_profile_config(ref self: ContractState) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

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

            // Initialize XP multiplier to 1x (100 basis points)
            store.set_xp_multiplier(XPMultiplier { key: 'xp_multiplier', multiplier: 100 });
        }

        fn set_xp_multiplier(ref self: ContractState, multiplier: u32) {
            assert(multiplier > 0, 'Multiplier must be > 0');

            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            store.set_xp_multiplier(XPMultiplier { key: 'xp_multiplier', multiplier });
        }

        fn get_xp_multiplier(self: @ContractState) -> u32 {
            let mut store = self.create_store();
            let multiplier_config = store.get_xp_multiplier();

            // If multiplier is not set, return default 1x (100)
            if multiplier_config.multiplier == 0 {
                100
            } else {
                multiplier_config.multiplier
            }
        }

        fn test_xp(
            ref self: ContractState,
            address: ContractAddress,
            season_id: u32,
            season_xp: u256,
            profile_xp: u256,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

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
        fn create_store(self: @ContractState) -> Store {
            let mut world = self.create_world();
            StoreTrait::new(world)
        }

        fn create_world(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS_BYTE())
        }

        fn _xp_with_multiplier(ref self: ContractState, ref store: Store, base_xp: u32) -> u32 {
            let multiplier_config = store.get_xp_multiplier();
            let multiplier = if multiplier_config.multiplier == 0 {
                100
            } else {
                multiplier_config.multiplier
            };
            (base_xp * multiplier) / 100
        }

        fn _apply_xp(
            ref self: ContractState,
            ref store: Store,
            address: ContractAddress,
            season_id: u32,
            is_season_active: bool,
            xp_earned: u32,
        ) {
            self._add_profile_xp(ref store, address, xp_earned.into());

            if is_season_active {
                self._add_season_xp(ref store, address, season_id, xp_earned.into());
            }
        }

        fn _streak_status(
            self: @ContractState, ref store: Store, address: ContractAddress,
        ) -> StreakStatus {
            let profile = store.get_profile(address);
            let state = store.get_streak_state(address);
            let current_day = get_current_day();
            let days_missed = if state.has_started && current_day > state.last_completed_day {
                current_day - state.last_completed_day - 1
            } else {
                0
            };
            let available: u64 = state.protectors_available.into();
            let is_broken = state.has_started && days_missed > available;
            let is_protected = state.has_started && days_missed > 0 && days_missed <= available;
            let longest_streak = if state.longest_streak > profile.daily_streak {
                state.longest_streak
            } else {
                profile.daily_streak
            };

            StreakStatus {
                player: address,
                current_streak: profile.daily_streak,
                longest_streak,
                last_completed_day: state.last_completed_day,
                protectors_available: state.protectors_available,
                protectors_needed: days_missed,
                days_missed,
                is_protected,
                is_broken,
            }
        }

        fn _increment_streak(ref self: ContractState, current_streak: u16) -> u16 {
            if current_streak == 65535 {
                current_streak
            } else {
                current_streak + 1
            }
        }

        fn _apply_daily_streak(
            ref self: ContractState,
            ref store: Store,
            address: ContractAddress,
            period_id: u64,
            mission_id: felt252,
        ) {
            let existing_completion = store.get_streak_day_completion(address, period_id);
            if existing_completion.completed {
                return;
            }

            let mut state = store.get_streak_state(address);
            if state.has_started && period_id <= state.last_completed_day {
                return;
            }

            let mut profile = store.get_profile(address);
            let mut protectors_used: u16 = 0;
            let mut reset = false;
            let new_streak = if state.has_started {
                let missed_days = period_id - state.last_completed_day - 1;
                if missed_days == 0 {
                    self._increment_streak(profile.daily_streak)
                } else {
                    let available: u64 = state.protectors_available.into();
                    let used_u64 = if missed_days < available {
                        missed_days
                    } else {
                        available
                    };
                    protectors_used = used_u64.try_into().unwrap();
                    state.protectors_available -= protectors_used;
                    state.protectors_used_total += protectors_used.into();

                    if missed_days <= available {
                        self._increment_streak(profile.daily_streak)
                    } else {
                        reset = true;
                        1
                    }
                }
            } else {
                1
            };

            profile.daily_streak = new_streak;
            state.player = address;
            state.last_completed_day = period_id;
            state.has_started = true;
            if new_streak > state.longest_streak {
                state.longest_streak = new_streak;
            }

            store.set_profile(@profile);
            store.set_streak_state(state);
            store
                .set_streak_day_completion(
                    StreakDayCompletion {
                        player: address, day: period_id, completed: true, mission_id, period_id,
                    },
                );

            self
                .emit(
                    DailyStreakUpdated {
                        player: address,
                        period_id,
                        mission_id,
                        current_streak: new_streak,
                        longest_streak: state.longest_streak,
                        protectors_used,
                        protectors_available: state.protectors_available,
                        reset,
                    },
                );
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

            store.set_profile(@profile);
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
                let level_data = get_season_level_data(season_id, level_to_check);

                // If level config doesn't exist (required_xp is 0), we've reached the max level
                if level_data.required_xp == 0 {
                    break;
                }

                if season_progress.season_xp >= level_data.required_xp {
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
                tournament_ticket: season_progress.tournament_ticket,
            };

            store.set_season_progress(@updated_progress);
        }
    }
}
