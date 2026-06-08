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
        StreakDayCompletion, StreakState, m_MissionXPAward, m_MissionXPProgress, m_SeasonConfig,
        m_SeasonProgress, m_StreakDayCompletion, m_StreakProtectorGrant, m_StreakState,
        m_XPMultiplier,
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
                TestResource::Model(m_StreakDayCompletion::TEST_CLASS_HASH),
                TestResource::Model(m_StreakProtectorGrant::TEST_CLASS_HASH),
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
        set_block_timestamp(21600 + 86400 * 3);

        xp.add_mission_xp(player, MISSION_PERIOD_DAILY, 1, 'm1', 'tpl', 1, 10);
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-status');
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-status');

        let state = streak_state(ref world, player);
        let status = xp.get_streak_status(player);
        assert(state.protectors_available == 1, 'grant idempotent');
        assert(status.days_missed == 1, 'status missed days');
        assert(status.protectors_available == 1, 'status protectors');
        assert(status.is_protected, 'status protected');
        assert(!status.is_broken, 'status not broken');
    }

    #[test]
    #[available_gas(100000000)]
    #[should_panic(expected: ('Protector slots full', 'ENTRYPOINT_FAILED',))]
    fn protector_grant_reverts_when_slots_are_full() {
        let (mut world, xp) = setup_world();
        let player = PLAYER_TWO();
        seed_profile(ref world, player);

        xp.grant_streak_protectors(player, 2, 'admin', 'grant-max');
        xp.grant_streak_protectors(player, 1, 'admin', 'grant-over');
    }
}
