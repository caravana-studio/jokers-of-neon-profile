#[cfg(test)]
mod tests_lives_system {
    use dojo::model::{Model, ModelStorage};
    use dojo::world::{WorldStorage, WorldStorageTrait, world};
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use starknet::ContractAddress;
    use starknet::testing::{
        set_account_contract_address, set_block_number, set_block_timestamp, set_contract_address,
    };
    use crate::constants::constants::{DEFAULT_NS_BYTE, LIVES_CONFIG_KEY};
    use crate::models::{
        LivesConfig, PlayerLives, SeasonProgress, m_LivesConfig, m_PlayerLives, m_SeasonProgress,
    };
    use crate::store::{Store, StoreTrait};
    use crate::systems::lives_system::{
        ILivesSystemDispatcher, ILivesSystemDispatcherTrait, lives_system,
    };

    fn OWNER() -> ContractAddress {
        'OWNER'.try_into().unwrap()
    }

    fn PLAYER() -> ContractAddress {
        'PLAYER'.try_into().unwrap()
    }

    const SEASON: u32 = 1;

    #[test]
    fn test_init_account_no_season_pass() {
        let (world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(player_lives.available_lives == 2, "initial lives should be 2");
        assert!(player_lives.max_lives == 2, "max lives should be 2");
        assert!(player_lives.next_life_timestamp == 0, "next life timestamp should be 0");
    }

    #[test]
    fn test_upgrade_account_with_season_pass() {
        let (world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());

        lives_system.init_account(PLAYER(), SEASON);
        lives_system.upgrade_account(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(player_lives.available_lives == 4, "initial lives should be 4");
        assert!(player_lives.max_lives == 4, "max lives should be 4");
        assert!(player_lives.next_life_timestamp == 0, "next life timestamp should be 0");
    }

    #[test]
    fn test_claim_with_no_lives_no_season_pass() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 1,
            "available lives should be 1 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_life_timestamp == 11,
            "next life timestamp should be 11 ({})",
            player_lives.next_life_timestamp,
        );
    }


    #[test]
    fn test_claim_with_no_lives_with_season_pass() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());

        lives_system.init_account(PLAYER(), SEASON);
        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 1,
            "available lives should be 1 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_life_timestamp == 6,
            "next life timestamp should be 6 ({})",
            player_lives.next_life_timestamp,
        );
    }

    #[test]
    fn test_remove_with_full_lives_no_season_pass() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 1,
            "available lives should be 1 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_life_timestamp == 11,
            "next life timestamp should be 11 ({})",
            player_lives.next_life_timestamp,
        );
    }

    #[test]
    fn test_remove_with_full_lives_with_season_pass() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        set_season_pass(ref store, PLAYER());
        lives_system.init_account(PLAYER(), SEASON);
        lives_system.upgrade_account(PLAYER(), SEASON);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 3,
            "available lives should be 3 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_life_timestamp == 6,
            "next life timestamp should be 6 ({})",
            player_lives.next_life_timestamp,
        );
    }

    #[test]
    fn test_remove_and_claim_full_lives_no_season_pass() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);

        lives_system.remove(PLAYER(), SEASON);
        set_block_timestamp(11);
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 2,
            "available lives should be 2 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_life_timestamp == 21,
            "next life timestamp should be 21 ({})",
            player_lives.next_life_timestamp,
        );
    }

    #[test]
    #[should_panic(
        expected: (
            "[LivesSystem] - You must have a season pass to upgrade your account",
            'ENTRYPOINT_FAILED',
        ),
    )]
    fn test_upgrade_account_no_season_pass() {
        let (world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);
        lives_system.upgrade_account(PLAYER(), SEASON);
    }

    #[test]
    #[should_panic(
        expected: (
            "[LivesSystem] - You already have the maximum number of lives", 'ENTRYPOINT_FAILED',
        ),
    )]
    fn test_claim_with_full_lives() {
        let (world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);
        lives_system.claim(PLAYER(), SEASON);
    }

    #[test]
    #[should_panic(
        expected: ("[LivesSystem] - You don't have any lives to use", 'ENTRYPOINT_FAILED'),
    )]
    fn test_remove_with_no_lives() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.init_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        lives_system.remove(PLAYER(), SEASON);
    }

    // ------------------------------------------------------------
    // UTILS
    // ------------------------------------------------------------
    fn setup() -> (WorldStorage, Store) {
        set_block_number(1);
        set_block_timestamp(1);
        impersonate(OWNER());
        let ndef = namespace_def();

        // Register the resources.
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());

        // Ensures permissions and initializations are synced.
        world.sync_perms_and_inits(contract_defs());
        (world, StoreTrait::new(world))
    }

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: DEFAULT_NS_BYTE(),
            resources: [
                TestResource::Model(m_PlayerLives::TEST_CLASS_HASH),
                TestResource::Model(m_LivesConfig::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonProgress::TEST_CLASS_HASH),
                TestResource::Contract(lives_system::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@DEFAULT_NS_BYTE(), @"lives_system")
                .with_writer_of([dojo::utils::bytearray_hash(@DEFAULT_NS_BYTE())].span())
                .with_init_calldata(array![OWNER().into()].span())
        ]
            .span()
    }

    fn impersonate(address: ContractAddress) {
        set_contract_address(address);
        set_account_contract_address(address);
    }

    fn lives_system_dispatcher(world: WorldStorage) -> ILivesSystemDispatcher {
        let (contract_address, _) = world.dns(@"lives_system").unwrap();
        ILivesSystemDispatcher { contract_address }
    }

    fn default_lives_config(ref store: Store) {
        store
            .set_lives_config(
                LivesConfig {
                    key: LIVES_CONFIG_KEY,
                    max_lives: 2,
                    max_lives_battle_pass: 4,
                    lives_cooldown: 10,
                    lives_cooldown_season_pass: 5,
                },
            );
    }

    fn set_season_pass(ref store: Store, player: ContractAddress) {
        store
            .set_season_progress(
                SeasonProgress {
                    address: player,
                    season_id: SEASON,
                    season_xp: 0,
                    has_season_pass: true,
                    claimable_rewards_id: [].span(),
                    tier: 0,
                    level: 0,
                },
            );
    }
}
