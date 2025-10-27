use starknet::ContractAddress;
use crate::models::{LivesConfig, PlayerLives};

#[starknet::interface]
pub trait ILivesSystem<T> {
    /// Claims a new life for a player if conditions are met.
    ///
    /// This method allows a player to claim a new life if they have not reached their maximum
    /// number of lives and the cooldown period has elapsed. The maximum lives and cooldown
    /// duration depend on whether the player has a season pass.
    ///
    /// # Parameters
    /// * `player` - The contract address of the player to claim a life for
    /// * `season_id` - The ID of the current season
    ///
    /// # Behavior
    /// - Checks if the player has reached maximum lives (fails if true)
    /// - Verifies that the cooldown period has elapsed (fails if not)
    /// - Increments the player's available lives by 1
    /// - Sets the next life timestamp based on the player's season pass status
    ///
    /// # Season Pass Benefits
    /// - Players with season pass have higher max lives and shorter cooldown
    /// - Cooldown and max lives are determined by `LivesConfig`
    fn claim(ref self: T, player: ContractAddress, season_id: u32);

    /// Removes a life from a player's account.
    ///
    /// This method consumes one life from the player's available lives. If the player
    /// was at maximum lives, it starts the cooldown timer for the next life regeneration.
    ///
    /// # Parameters
    /// * `player` - The contract address of the player to remove a life from
    /// * `season_id` - The ID of the current season
    ///
    /// # Behavior
    /// - Verifies the player has at least one life available
    /// - Decrements the player's available lives by 1
    /// - If player was at max lives, starts cooldown timer for next life regeneration
    /// - Cooldown duration depends on player's season pass status
    fn remove(ref self: T, player: ContractAddress, season_id: u32);

    /// Initializes a new player account with default lives configuration.
    ///
    /// This method sets up a new player with the maximum number of lives available
    /// based on the current lives configuration. This is typically called when a
    /// player first joins a season.
    ///
    /// # Parameters
    /// * `player` - The contract address of the player to initialize
    /// * `season_id` - The ID of the season to initialize the player for
    ///
    /// # Behavior
    /// - Creates a new `PlayerLives` record for the player
    /// - Sets available_lives to the maximum allowed (from config)
    /// - Sets max_lives to the standard maximum (not battle pass maximum)
    /// - Initializes next_live_timestamp to 0 (no cooldown initially)
    fn init_account(ref self: T, player: ContractAddress, season_id: u32);

    /// Upgrades a player's account to battle pass benefits.
    ///
    /// This method upgrades an existing player account to take advantage of battle pass
    /// benefits, including higher maximum lives and shorter cooldown periods. The player
    /// must already have a season pass to use this method.
    ///
    /// # Parameters
    /// * `player` - The contract address of the player to upgrade
    /// * `season_id` - The ID of the season to upgrade the player for
    ///
    /// # Prerequisites
    /// - The player must have a valid season pass for the specified season
    ///
    /// # Behavior
    /// - Verifies the player has a season pass (fails if not)
    /// - Preserves the player's current available lives
    /// - Updates max_lives to the battle pass maximum
    /// - Adjusts next_live_timestamp to use battle pass cooldown
    fn upgrade_account(ref self: T, player: ContractAddress, season_id: u32);

    /// Sets the global lives configuration for the system.
    ///
    /// This method allows the configuration of the lives system to be updated.
    ///
    /// # Parameters
    /// * `config` - The new `LivesConfig` to set
    ///
    /// # Behavior
    /// - Updates the global lives configuration with the new values
    fn init_lives_config(ref self: T);

    /// Retrieves the current lives information for a specific player.
    ///
    /// This method returns the complete lives state for a player in a given season,
    /// including available lives, maximum lives, and cooldown information.
    ///
    /// # Parameters
    /// * `player` - The contract address of the player to query
    /// * `season_id` - The ID of the season to query
    ///
    /// # Returns
    /// A `PlayerLives` struct containing:
    /// - `player`: The player's contract address
    /// - `season_id`: The season ID
    /// - `available_lives`: Current number of lives the player can use
    /// - `max_lives`: Maximum number of lives the player can have
    /// - `next_live_timestamp`: Unix timestamp when the next life becomes available
    fn get_player_lives(self: @T, player: ContractAddress, season_id: u32) -> PlayerLives;

    /// Retrieves the global lives configuration for the system.
    ///
    /// This method returns the system-wide configuration that determines how lives
    /// work, including maximum lives, cooldown periods, and battle pass benefits.
    ///
    /// # Returns
    /// A `LivesConfig` struct containing:
    /// - `key`: Configuration identifier (LIVES_CONFIG_KEY)
    /// - `max_lives`: Maximum lives for standard players
    /// - `max_lives_battle_pass`: Maximum lives for battle pass holders
    /// - `lives_cooldown`: Cooldown period in seconds for standard players
    /// - `lives_cooldown_battle_pass`: Cooldown period in seconds for battle pass holders
    fn get_lives_config(self: @T) -> LivesConfig;
}

#[dojo::contract]
pub mod lives_system {
    use openzeppelin_access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::{ContractAddress, get_block_timestamp};
    use crate::constants::constants::{LIVES_CONFIG_KEY, SIX_HOURS, TWELVE_HOURS};
    use crate::models::{LivesConfig, PlayerLives};
    use crate::store::{Store, StoreTrait};

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
    }

    fn dojo_init(ref self: ContractState, owner: ContractAddress) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, owner);
    }

    #[abi(embed_v0)]
    impl LivesSystem of super::ILivesSystem<ContractState> {
        fn claim(ref self: ContractState, player: ContractAddress, season_id: u32) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = self.default_store();
            let mut player_lives = store.get_player_lives(player, season_id);

            // Get config and check if player has season pass
            let config = store.get_lives_config();
            let has_season_pass = store.get_season_progress(player, season_id).has_season_pass;

            let max_lives = if has_season_pass {
                config.max_lives_battle_pass
            } else {
                config.max_lives
            };

            // Check if player has max lives
            assert!(
                player_lives.available_lives < max_lives,
                "[LivesSystem] - You already have the maximum number of lives",
            );

            // Check if cooldown has passed
            let current_timestamp = get_block_timestamp();
            assert!(
                current_timestamp >= player_lives.next_live_timestamp,
                "[LivesSystem] - You have to wait {} seconds to claim a new life",
                player_lives.next_live_timestamp - current_timestamp,
            );

            // Get cooldown
            let cooldown = if has_season_pass {
                config.lives_cooldown_season_pass
            } else {
                config.lives_cooldown
            };

            player_lives.available_lives += 1;
            player_lives.next_live_timestamp = current_timestamp + cooldown;
            store.set_player_lives(player_lives);
        }

        fn remove(ref self: ContractState, player: ContractAddress, season_id: u32) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = self.default_store();
            let mut player_lives = store.get_player_lives(player, season_id);

            assert!(
                player_lives.available_lives > 0, "[LivesSystem] - You don't have any lives to use",
            );
            // Get config and check if player has season pass
            let config = store.get_lives_config();
            let has_season_pass = store.get_season_progress(player, season_id).has_season_pass;

            let max_lives = if has_season_pass {
                config.max_lives_battle_pass
            } else {
                config.max_lives
            };

            if player_lives.available_lives == max_lives {
                let cooldown = if has_season_pass {
                    config.lives_cooldown_season_pass
                } else {
                    config.lives_cooldown
                };
                player_lives.next_live_timestamp = get_block_timestamp() + cooldown;
            }

            player_lives.available_lives -= 1;
            store.set_player_lives(player_lives);
        }

        fn init_account(ref self: ContractState, player: ContractAddress, season_id: u32) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = self.default_store();
            let config = store.get_lives_config();

            store
                .set_player_lives(
                    PlayerLives {
                        player: player,
                        season_id: season_id,
                        available_lives: config.max_lives,
                        max_lives: config.max_lives,
                        next_live_timestamp: 0,
                    },
                );
        }

        fn upgrade_account(ref self: ContractState, player: ContractAddress, season_id: u32) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = self.default_store();
            let config = store.get_lives_config();
            let has_season_pass = store.get_season_progress(player, season_id).has_season_pass;
            assert!(
                has_season_pass,
                "[LivesSystem] - You must have a season pass to upgrade your account",
            );

            let player_lives = store.get_player_lives(player, season_id);
            let cooldown = if player_lives.next_live_timestamp > config.lives_cooldown_season_pass {
                config.lives_cooldown_season_pass
            } else {
                player_lives.next_live_timestamp
            };

            store
                .set_player_lives(
                    PlayerLives {
                        player: player,
                        season_id: season_id,
                        available_lives: player_lives.available_lives
                            + (config.max_lives_battle_pass - config.max_lives),
                        max_lives: config.max_lives_battle_pass,
                        next_live_timestamp: cooldown,
                    },
                );
        }

        fn init_lives_config(ref self: ContractState) {
            self.init_default_lives_config();
        }

        fn get_player_lives(
            self: @ContractState, player: ContractAddress, season_id: u32,
        ) -> PlayerLives {
            let mut store = self.default_store();
            store.get_player_lives(player, season_id)
        }

        fn get_lives_config(self: @ContractState) -> LivesConfig {
            let mut store = self.default_store();
            store.get_lives_config()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn init_default_lives_config(ref self: ContractState) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = self.default_store();
            store
                .set_lives_config(
                    LivesConfig {
                        key: LIVES_CONFIG_KEY,
                        max_lives: 2,
                        max_lives_battle_pass: 4,
                        lives_cooldown: 10, // TODO:
                        lives_cooldown_season_pass: 20, // TODO:
                    },
                );
        }

        fn default_store(self: @ContractState) -> Store {
            let world = self.world(@"jokers_of_neon_profile");
            StoreTrait::new(world)
        }
    }
}
