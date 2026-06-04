#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::{WorldStorage, WorldStorageTrait, world};
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use jokers_of_neon_lib::models::external::profile::{Profile, m_Profile};
    use jokers_of_neon_profile::constants::constants::{DEFAULT_NS_BYTE, STREAK_PROTECTOR_REWARD_ID};
    use jokers_of_neon_profile::constants::season_configs::get_season_level_data;
    use jokers_of_neon_profile::models::{
        SeasonConfig, SeasonProgress, SeasonRewardClaim, m_SeasonConfig, m_SeasonProgress,
        m_SeasonRewardClaim,
    };
    use jokers_of_neon_profile::systems::permission_system::{m_PermissionConfig, permission_system};
    use jokers_of_neon_profile::systems::season_system::{
        ISeasonSystemDispatcher, ISeasonSystemDispatcherTrait, season_system,
    };
    use starknet::ContractAddress;

    const SEASON_ID: u32 = 3;

    fn OWNER() -> ContractAddress {
        'OWNER'.try_into().unwrap()
    }

    fn PLAYER() -> ContractAddress {
        'PLAYER'.try_into().unwrap()
    }

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: DEFAULT_NS_BYTE(),
            resources: array![
                TestResource::Model(m_Profile::TEST_CLASS_HASH),
                TestResource::Model(m_PermissionConfig::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonConfig::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonProgress::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonRewardClaim::TEST_CLASS_HASH),
                TestResource::Contract(permission_system::TEST_CLASS_HASH),
                TestResource::Contract(season_system::TEST_CLASS_HASH),
            ]
                .span(),
        }
    }

    fn contract_defs() -> Span<ContractDef> {
        array![
            ContractDefTrait::new(@DEFAULT_NS_BYTE(), @"permission_system")
                .with_init_calldata(array![OWNER().into()].span()),
            ContractDefTrait::new(@DEFAULT_NS_BYTE(), @"season_system")
                .with_writer_of(array![dojo::utils::bytearray_hash(@DEFAULT_NS_BYTE())].span()),
        ]
            .span()
    }

    fn setup_world() -> (WorldStorage, ISeasonSystemDispatcher) {
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, array![namespace_def()].span());
        world.sync_perms_and_inits(contract_defs());
        let (season_system_address, _) = world.dns(@"season_system").unwrap();
        let season = ISeasonSystemDispatcher { contract_address: season_system_address };
        world.write_model_test(@SeasonConfig { season_id: SEASON_ID, is_active: true });
        (world, season)
    }

    fn seed_profile_and_progress(ref world: WorldStorage, player: ContractAddress, level: u32) {
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
        world
            .write_model_test(
                @SeasonProgress {
                    address: player,
                    season_id: SEASON_ID,
                    season_xp: 0,
                    has_season_pass: false,
                    claimable_rewards_id: array![].span(),
                    season_pass_unlocked_at_level: 0,
                    level,
                    tournament_ticket: 0,
                },
            );
    }

    #[test]
    fn season_config_includes_streak_protector_rewards() {
        let level_2 = get_season_level_data(SEASON_ID, 2);
        let level_5 = get_season_level_data(SEASON_ID, 5);
        let level_12 = get_season_level_data(SEASON_ID, 12);
        let level_13 = get_season_level_data(SEASON_ID, 13);
        let level_18 = get_season_level_data(SEASON_ID, 18);
        let level_24 = get_season_level_data(SEASON_ID, 24);
        let level_27 = get_season_level_data(SEASON_ID, 27);
        let level_31 = get_season_level_data(SEASON_ID, 31);

        assert(*level_2.free_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l2 free');
        assert(*level_5.premium_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l5 premium');
        assert(*level_12.free_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l12 free');
        assert(*level_13.premium_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l13 premium');
        assert(*level_18.premium_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l18 premium');
        assert(*level_24.premium_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l24 premium');
        assert(*level_27.free_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l27 free');
        assert(*level_31.premium_rewards.at(0) == STREAK_PROTECTOR_REWARD_ID, 'bad l31 premium');
    }

    #[test]
    #[available_gas(100000000)]
    fn protector_only_reward_can_be_marked_claimed() {
        let (mut world, season) = setup_world();
        let player = PLAYER();
        seed_profile_and_progress(ref world, player, 2);

        season.claim_season_rewards(player, SEASON_ID, 2, false);

        let claim: SeasonRewardClaim = world.read_model((player, SEASON_ID, 2));
        assert(claim.free_claimed, 'free claim');
        assert(!claim.premium_claimed, 'premium claim');
    }
}
