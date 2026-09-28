#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::{WorldStorage, WorldStorageTrait, world};
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use jokers_of_neon_lib::models::external::profile::{
        Profile, ProfileLevelConfig, m_Profile, m_ProfileLevelConfig,
    };
    use jokers_of_neon_profile::constants::constants::{
        DEFAULT_NS_BYTE, MISSION_PERIOD_DAILY, MISSION_PERIOD_WEEKLY,
    };
    use jokers_of_neon_profile::models::{
        SeasonConfig, SeasonProgress, StreakDayCompletion, StreakRepair, StreakRewardGrant,
        StreakState, m_MissionXPAward, m_MissionXPProgress, m_SeasonConfig, m_SeasonProgress,
        m_StreakDayCompletion, m_StreakMaintenanceConfig, m_StreakProtectorGrant, m_StreakRepair,
        m_StreakRewardGrant, m_StreakState, m_XPMultiplier,
    };
    use jokers_of_neon_profile::systems::permission_system::{m_PermissionConfig, permission_system};
    use jokers_of_neon_profile::systems::xp_system::{
        IXPSystemDispatcher, IXPSystemDispatcherTrait, xp_system,
    };
    use starknet::ContractAddress;
    use starknet::testing::set_block_timestamp;

    fn OWNER() -> ContractAddress {
        'OWNER'.try_into().unwrap()
    }

    fn PLAYER_ONE() -> ContractAddress {
        'PLAYER_ONE'.try_into().unwrap()
    }

    fn PLAYER_TWO() -> ContractAddress {
        'PLAYER_TWO'.try_into().unwrap()
    }

    fn PLAYER_THREE() -> ContractAddress {
        'PLAYER_THREE'.try_into().unwrap()
    }

    fn PLAYER_FOUR() -> ContractAddress {
        'PLAYER_FOUR'.try_into().unwrap()
    }

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: DEFAULT_NS_BYTE(),
            resources: array![
                TestResource::Model(m_Profile::TEST_CLASS_HASH),
                TestResource::Model(m_ProfileLevelConfig::TEST_CLASS_HASH),
                TestResource::Model(m_PermissionConfig::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonConfig::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonProgress::TEST_CLASS_HASH),
                TestResource::Model(m_MissionXPProgress::TEST_CLASS_HASH),
                TestResource::Model(m_MissionXPAward::TEST_CLASS_HASH),
                TestResource::Model(m_XPMultiplier::TEST_CLASS_HASH),
                TestResource::Model(m_StreakState::TEST_CLASS_HASH),
                TestResource::Model(m_StreakMaintenanceConfig::TEST_CLASS_HASH),
                TestResource::Model(m_StreakRepair::TEST_CLASS_HASH),
                TestResource::Model(m_StreakDayCompletion::TEST_CLASS_HASH),
                TestResource::Model(m_StreakProtectorGrant::TEST_CLASS_HASH),
                TestResource::Model(m_StreakRewardGrant::TEST_CLASS_HASH),
                TestResource::Contract(permission_system::TEST_CLASS_HASH),
                TestResource::Contract(xp_system::TEST_CLASS_HASH),
            ]
                .span(),
        }
    }

    fn contract_defs() -> Span<ContractDef> {
        array![
            ContractDefTrait::new(@DEFAULT_NS_BYTE(), @"permission_system")
                .with_init_calldata(array![OWNER().into()].span()),
            ContractDefTrait::new(@DEFAULT_NS_BYTE(), @"xp_system")
                .with_writer_of(array![dojo::utils::bytearray_hash(@DEFAULT_NS_BYTE())].span()),
        ]
            .span()
    }

    fn setup_world() -> (WorldStorage, IXPSystemDispatcher) {
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, array![namespace_def()].span());
        world.sync_perms_and_inits(contract_defs());
        let (xp_system_address, _) = world.dns(@"xp_system").unwrap();
        let xp = IXPSystemDispatcher { contract_address: xp_system_address };
        world.write_model_test(@ProfileLevelConfig { level: 1, required_xp: 100000.into() });
        (world, xp)
    }

    fn seed_profile(ref world: WorldStorage, player: ContractAddress) {
        world
            .write_model_test(
                @Profile {
                    address: player,
                    username: "tester",
                    total_xp: 0,
                    xp: 0,
                    level: 0,
                    available_games: 0,
                    max_available_games: 0,
                    daily_streak: 0,
                    banned: false,
                    badges_ids: array![].span(),
                    avatar_id: 1,
                    claimable_packs: array![].span(),
                },
            );
    }

    fn profile(ref world: WorldStorage, player: ContractAddress) -> Profile {
        world.read_model(player)
    }

    fn streak_state(ref world: WorldStorage, player: ContractAddress) -> StreakState {
        world.read_model(player)
    }

    fn seed_active_season(ref world: WorldStorage, player: ContractAddress, season_id: u32) {
        world.write_model_test(@SeasonConfig { season_id, is_active: true });
        world
            .write_model_test(
                @SeasonProgress {
                    address: player,
                    season_id,
                    season_xp: 0,
                    has_season_pass: false,
                    claimable_rewards_id: array![].span(),
                    season_pass_unlocked_at_level: 0,
                    level: 0,
                    tournament_ticket: 0,
                },
            );
    }

    fn season_progress(
        ref world: WorldStorage, player: ContractAddress, season_id: u32,
    ) -> SeasonProgress {
        world.read_model((player, season_id))
    }

    fn streak_reward_grant(
        ref world: WorldStorage, player: ContractAddress, source: felt252, source_id: felt252,
    ) -> StreakRewardGrant {
        world.read_model((player, source, source_id))
    }

    fn streak_repair(
        ref world: WorldStorage, player: ContractAddress, incident_id: felt252,
    ) -> StreakRepair {
        world.read_model((player, incident_id))
    }

    fn set_current_day(day: u64) {
        set_block_timestamp(21600 + 86400 * day);
    }

    #[test]
    #[available_gas(100000000)]
    fn daily_streak_starts_once_per_day_and_continues() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_ONE();
        seed_profile(ref world, player);

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 10, 'm1', 'tpl', 1, 10);
        assert(profile(ref world, player).daily_streak == 1, 'first daily streak');

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 10, 'm2', 'tpl', 2, 20);
        assert(profile(ref world, player).daily_streak == 1, 'same day duplicate');

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 11, 'm3', 'tpl', 3, 30);
        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 2, 'next day streak');
        assert(state.last_completed_day == 11, 'last completed day');
        assert(state.longest_streak == 2, 'longest streak');

        let completion: StreakDayCompletion = world.read_model((player, 11));
        assert(completion.completed, 'completion stored');
        assert(completion.mission_id == 'm3', 'completion mission id');
    }

    #[test]
    #[available_gas(100000000)]
    fn weekly_mission_xp_does_not_touch_streak() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_TWO();
        seed_profile(ref world, player);

        xp.add_mission_xp(player, MISSION_PERIOD_WEEKLY, 7, 'w1', 'tpl', 1, 50);

        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 0, 'weekly streak');
        assert(!state.has_started, 'weekly state');
    }

    #[test]
    #[available_gas(100000000)]
    fn protector_covers_one_missed_day() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_THREE();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 1, 'admin', 'grant1');
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 3, 'm2', 'tpl', 1, 10);

        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 2, 'protected streak');
        assert(state.protectors_available == 0, 'protector spent');
        assert(state.protectors_used_total == 1, 'protector used total');
    }

    #[test]
    #[available_gas(100000000)]
    fn missing_day_without_protector_resets_streak() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_FOUR();
        seed_profile(ref world, player);

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 3, 'm2', 'tpl', 1, 10);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 2, 'old', 'tpl', 1, 10);

        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 1, 'reset streak');
        assert(state.last_completed_day == 3, 'old event ignored');
        assert(state.longest_streak == 1, 'longest after reset');
    }

    #[test]
    #[available_gas(100000000)]
    fn protector_grants_are_idempotent_and_status_reports_gap() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_ONE();
        seed_profile(ref world, player);
        set_current_day(1);

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-status');
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-status');

        let state = streak_state(ref world, player);
        set_current_day(3);
        let status = xp.get_streak_status(player);
        assert(state.protectors_available == 1, 'grant idempotent');
        assert(status.days_missed == 1, 'status missed days');
        assert(status.protectors_available == 0, 'status protectors');
        assert(status.last_completed_day == 2, 'status accounted day');
        assert(status.is_protected, 'status protected');
        assert(!status.is_broken, 'status not broken');
    }

    #[test]
    #[available_gas(100000000)]
    fn status_reports_broken_when_missed_days_exceed_protectors() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_THREE();
        seed_profile(ref world, player);
        set_current_day(1);

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 2, 'admin', 'grant-two');

        set_current_day(5);
        let status = xp.get_streak_status(player);
        let state = streak_state(ref world, player);

        assert(profile(ref world, player).daily_streak == 1, 'view keeps raw streak');
        assert(state.protectors_available == 2, 'view keeps raw protectors');
        assert(status.current_streak == 0, 'effective broken streak');
        assert(status.protectors_available == 0, 'effective protectors spent');
        assert(status.protectors_needed == 3, 'status needed');
        assert(status.days_missed == 3, 'status missed days');
        assert(status.last_completed_day == 4, 'effective accounted day');
        assert(!status.is_protected, 'not protected');
        assert(status.is_broken, 'status broken');
    }

    #[test]
    #[available_gas(100000000)]
    fn daily_mission_after_uncovered_gap_consumes_all_protectors_and_restarts() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_FOUR();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 2, 'admin', 'grant-two');
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 5, 'm2', 'tpl', 1, 10);

        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 1, 'restarted streak');
        assert(state.last_completed_day == 5, 'last completed day');
        assert(state.protectors_available == 0, 'all protectors spent');
        assert(state.protectors_used_total == 2, 'used total');
        assert(state.longest_streak == 1, 'longest after restart');
    }

    #[test]
    #[available_gas(100000000)]
    fn zero_streak_does_not_consume_a_protector_before_restarting() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_ONE();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);

        set_current_day(4);
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-after-break');
        assert(profile(ref world, player).daily_streak == 0, 'streak already broken');

        set_current_day(5);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 5, 'm2', 'tpl', 1, 10);

        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 1, 'streak restarted');
        assert(state.protectors_available == 1, 'protector preserved');
        assert(state.protectors_used_total == 0, 'protector not consumed');
    }

    #[test]
    #[available_gas(100000000)]
    fn maintenance_days_preserve_streak_without_consuming_protectors() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_ONE();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 1, 'admin', 'maintenance-protector');
        xp.configure_streak_maintenance('incident-1', 2, 3, true);

        set_current_day(4);
        let status = xp.get_streak_status(player);
        assert(status.current_streak == 1, 'maintenance keeps streak');
        assert(status.days_missed == 0, 'maintenance gap excluded');
        assert(status.protectors_available == 1, 'protector preserved');

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 4, 'm2', 'tpl', 1, 10);
        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 2, 'streak continues');
        assert(state.last_completed_day == 4, 'completion advances day');
        assert(state.protectors_available == 1, 'protector not spent');
        assert(state.protectors_used_total == 0, 'no protector usage');
    }

    #[test]
    #[available_gas(100000000)]
    fn non_maintenance_gap_still_resets_streak() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_TWO();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.configure_streak_maintenance('incident-2', 2, 3, true);

        set_current_day(5);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 5, 'm2', 'tpl', 1, 10);

        assert(profile(ref world, player).daily_streak == 1, 'outside gap resets');
        assert(streak_state(ref world, player).last_completed_day == 5, 'day advances');
    }

    #[test]
    #[available_gas(100000000)]
    #[should_panic(expected: ('Invalid maintenance range', 'ENTRYPOINT_FAILED'))]
    fn invalid_maintenance_range_is_rejected() {
        let (_world, xp) = setup_world();
        xp.configure_streak_maintenance('invalid-incident', 4, 3, true);
    }

    #[test]
    #[available_gas(100000000)]
    fn repair_is_atomic_idempotent_and_continues() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_THREE();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 1, 'admin', 'repair-protector');

        xp.restore_streak(player, 7, 3, 'incident-repair');
        xp.restore_streak(player, 9, 4, 'incident-repair');

        let repaired_profile = profile(ref world, player);
        let repaired_state = streak_state(ref world, player);
        let repair = streak_repair(ref world, player, 'incident-repair');
        assert(repaired_profile.daily_streak == 7, 'streak repaired once');
        assert(repaired_state.last_completed_day == 3, 'repair advances day');
        assert(repaired_state.longest_streak == 7, 'longest preserved');
        assert(repaired_state.protectors_available == 1, 'protectors preserved');
        assert(repair.previous_streak == 1, 'previous streak audited');
        assert(repair.restored_streak == 7, 'restored streak audited');
        assert(repair.applied, 'repair receipt stored');

        set_current_day(4);
        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 4, 'm2', 'tpl', 1, 10);
        assert(profile(ref world, player).daily_streak == 8, 'repaired streak continues');

        xp.restore_streak(player, 6, 2, 'lower-repair');
        assert(profile(ref world, player).daily_streak == 8, 'repair never lowers streak');
        assert(streak_state(ref world, player).last_completed_day == 4, 'repair never lowers day');
    }

    #[test]
    #[available_gas(100000000)]
    fn protector_grant_materializes_stale_gap_before_slot_check() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_ONE();
        seed_profile(ref world, player);
        set_current_day(1);

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-one');

        set_current_day(3);
        xp.grant_streak_protectors(player, 2, 'season', 'reward-two');

        let state = streak_state(ref world, player);
        assert(profile(ref world, player).daily_streak == 1, 'streak preserved');
        assert(state.last_completed_day == 2, 'gap accounted');
        assert(state.protectors_available == 2, 'slots refilled');
        assert(state.protectors_used_total == 1, 'old protector consumed');
    }

    #[test]
    #[available_gas(100000000)]
    #[should_panic(expected: ('Protector slots full', 'ENTRYPOINT_FAILED'))]
    fn protector_grant_reverts_when_slots_are_full() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_TWO();
        seed_profile(ref world, player);

        set_current_day(1);
        xp.grant_streak_protectors(player, 2, 'admin', 'grant-max');
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-over');
    }

    #[test]
    #[available_gas(100000000)]
    fn streak_reward_grants_xp_and_protectors() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_ONE();
        let season_id = 3;
        seed_profile(ref world, player);
        seed_active_season(ref world, player, season_id);

        xp.claim_streak_reward(player, season_id, 50, 1, 'streak', 'd7');

        let player_profile = profile(ref world, player);
        let progress = season_progress(ref world, player, season_id);
        let state = streak_state(ref world, player);
        let grant = streak_reward_grant(ref world, player, 'streak', 'd7');

        assert(player_profile.total_xp == 50, 'profile total xp');
        assert(player_profile.xp == 50, 'profile xp');
        assert(progress.season_xp == 50, 'season xp');
        assert(progress.tournament_ticket == 0, 'ticket unchanged');
        assert(state.protectors_available == 1, 'protector granted');
        assert(grant.claimed, 'grant claimed');
        assert(grant.xp_amount == 50, 'grant xp');
        assert(grant.protectors_requested == 1, 'requested protector');
        assert(grant.protectors_granted == 1, 'granted protector');
    }

    #[test]
    #[available_gas(100000000)]
    fn streak_reward_is_idempotent_by_source() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_TWO();
        let season_id = 3;
        seed_profile(ref world, player);
        seed_active_season(ref world, player, season_id);

        xp.claim_streak_reward(player, season_id, 50, 1, 'streak', 'd7');
        xp.claim_streak_reward(player, season_id, 50, 1, 'streak', 'd7');

        assert(profile(ref world, player).total_xp == 50, 'profile xp once');
        assert(season_progress(ref world, player, season_id).season_xp == 50, 'season xp once');
        assert(
            season_progress(ref world, player, season_id).tournament_ticket == 0,
            'ticket unchanged',
        );
        assert(streak_state(ref world, player).protectors_available == 1, 'protector once');
    }

    #[test]
    #[available_gas(100000000)]
    fn streak_reward_protector_without_slot_does_not_revert() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_THREE();
        let season_id = 3;
        seed_profile(ref world, player);
        seed_active_season(ref world, player, season_id);

        xp.grant_streak_protectors(player, 2, 'admin', 'grant-max');
        xp.claim_streak_reward(player, season_id, 0, 1, 'streak', 'slot-full');

        let state = streak_state(ref world, player);
        let grant = streak_reward_grant(ref world, player, 'streak', 'slot-full');

        assert(state.protectors_available == 2, 'protectors stay full');
        assert(grant.claimed, 'claim stored');
        assert(grant.protectors_requested == 1, 'requested stored');
        assert(grant.protectors_granted == 0, 'none granted');
    }
}
