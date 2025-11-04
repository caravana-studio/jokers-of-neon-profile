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
        set_account_contract_address, set_block_timestamp, set_contract_address,
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

    // ------------------------------------------------------------
    // SEASON PASS TESTS
    // ------------------------------------------------------------

    #[test]
    fn test_season_pass_upgrade_account() {
        let (world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 4);
        assert_current_cooldown(player_lives, 5);
    }

    #[test]
    fn test_season_pass_first_claim() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        set_season_pass(ref store, PLAYER());
        lives_system.claim(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 4);
        assert_current_cooldown(player_lives, 5);
    }

    #[test]
    fn test_season_pass_claim_1_live() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // season_pass_cooldown: 10
        set_block_timestamp(10);
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 10 + 5);
    }

    #[test]
    fn test_season_pass_claim_2_lives() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // season_pass_cooldown: 5
        // so with timestamp: 15 should be able to claim 2 lives
        set_block_timestamp(15);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 15 + 5);
    }

    #[test]
    fn test_season_pass_claim_3_lives() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // season_pass_cooldown: 5
        // so with timestamp: 20 should be able to claim 3 lives
        set_block_timestamp(20);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 3);
        assert_current_cooldown(player_lives, 20 + 5);
    }

    #[test]
    fn test_season_pass_claim_4_lives() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // season_pass_cooldown: 5
        // so with timestamp: 25 should be able to claim 3 lives
        set_block_timestamp(25);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 4);
        assert_current_cooldown(player_lives, 25 + 5);
    }

    #[test]
    fn test_season_pass_claim_4_lives_when_times_higher() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // season_pass_cooldown: 5
        // so with timestamp: 1000 should be able to claim full lives
        set_block_timestamp(1000);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 4);
        assert_current_cooldown(player_lives, 1000 + 5);
    }

    #[test]
    fn test_season_pass_claim() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());

        lives_system.upgrade_account(PLAYER(), SEASON);

        // Set available lives to 1
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                1,
            );

        // season_pass_cooldown: 5
        set_block_timestamp(5);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 5 + 5);
    }

    #[test]
    fn test_season_pass_remove_all() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 3);
        assert_current_cooldown(player_lives, 5);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 5);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 5);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 0);
        assert_current_cooldown(player_lives, 5);
    }

    #[test]
    fn test_season_pass_remove_and_claim() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        // Set season pass on true for PLAYER()
        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 3);
        assert_current_cooldown(player_lives, 5);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 5);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 5);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 0);
        assert_current_cooldown(player_lives, 5);

        // Wait 5 seconds to claim a new life
        set_block_timestamp(5);
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 5 + 5);
    }

    // ------------------------------------------------------------
    // NO SEASON PASS TESTS
    // ------------------------------------------------------------

    #[test]
    fn test_first_claim() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);

        lives_system.claim(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 10);
    }

    #[test]
    fn test_claim_1_live() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // cooldown: 10
        set_block_timestamp(10);
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 10 + 10);
    }

    #[test]
    fn test_claim_2_lives() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // cooldown: 10
        // so with timestamp: 20 should be able to claim 2 lives
        set_block_timestamp(20);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 20 + 10);
    }


    #[test]
    fn test_claim_2_lives_when_times_higher() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        // Set available lives to 0
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                0,
            );

        // cooldown: 10
        // so with timestamp: 1000 should be able to claim full lives
        set_block_timestamp(1000);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 1000 + 10);
    }

    #[test]
    fn test_claim() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        // Set available lives to 1
        world
            .write_member(
                Model::<PlayerLives>::ptr_from_keys((PLAYER(), SEASON)),
                selector!("available_lives"),
                1,
            );

        // cooldown: 10
        set_block_timestamp(10);
        assert!(lives_system.has_lives_to_claim(PLAYER(), SEASON), "should have lives to claim");
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 2);
        assert_current_cooldown(player_lives, 10 + 10);
    }

    #[test]
    fn test_remove_all() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 10);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 0);
        assert_current_cooldown(player_lives, 10);
    }

    #[test]
    fn test_remove_and_claim() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 10);

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 0);
        assert_current_cooldown(player_lives, 10);

        // Wait 10 seconds to claim a new life
        set_block_timestamp(10);
        lives_system.claim(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert_available_lives(player_lives, 1);
        assert_current_cooldown(player_lives, 10 + 10);
    }

    #[test]
    fn test_remove_and_then_upgrade() {
        let (mut world, mut store) = setup();
        default_lives_config(ref store);
        let lives_system = lives_system_dispatcher(world);
        simulate_init_account(ref store, PLAYER());

        lives_system.remove(PLAYER(), SEASON);
        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 1,
            "available lives should be 1 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_live_timestamp == 10,
            "next life timestamp should be 10 ({})",
            player_lives.next_live_timestamp,
        );

        set_season_pass(ref store, PLAYER());
        lives_system.upgrade_account(PLAYER(), SEASON);

        let player_lives = store.get_player_lives(PLAYER(), SEASON);
        assert!(
            player_lives.available_lives == 3,
            "available lives should be 3 ({})",
            player_lives.available_lives,
        );
        assert!(
            player_lives.next_live_timestamp == 5,
            "next life timestamp should be 5 ({})",
            player_lives.next_live_timestamp,
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
        simulate_init_account(ref store, PLAYER());

        assert!(
            !lives_system.has_lives_to_claim(PLAYER(), SEASON), "should not have lives to claim",
        );
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
        simulate_init_account(ref store, PLAYER());

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
                    season_pass_unlocked_at_level: 0,
                    claimable_rewards_id: array![].span(),
                    level: 0,
                },
            );
    }

    fn simulate_init_account(ref store: Store, player: ContractAddress) {
        let lives_config = store.get_lives_config();
        store
            .set_player_lives(
                PlayerLives {
                    player: player,
                    season_id: SEASON,
                    available_lives: lives_config.max_lives,
                    max_lives: lives_config.max_lives,
                    next_live_timestamp: 0,
                },
            );
    }

    fn assert_available_lives(player_lives: PlayerLives, expected: u32) {
        assert!(
            player_lives.available_lives == expected,
            "available lives should be {} (actual: {})",
            expected,
            player_lives.available_lives,
        );
    }

    fn assert_current_cooldown(player_lives: PlayerLives, expected: u64) {
        assert!(
            player_lives.next_live_timestamp == expected,
            "next life timestamp should be {} (actual: {})",
            expected,
            player_lives.next_live_timestamp,
        );
    }
}

