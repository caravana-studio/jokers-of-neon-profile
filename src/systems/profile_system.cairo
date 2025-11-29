use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
use starknet::ContractAddress;
use crate::models::SeasonProgress;

#[starknet::interface]
pub trait IJokersProfile<T> {
    fn create_profile(ref self: T, address: ContractAddress, username: ByteArray, avatar_id: u16);
    fn add_stats(ref self: T, player_stats: PlayerStats);
    fn update_avatar(ref self: T, player_address: ContractAddress, avatar_id: u16);
    fn get_profile(self: @T, player_address: ContractAddress) -> Profile;
    fn get_player_stats(self: @T, player_address: ContractAddress) -> PlayerStats;
    fn get_profile_level_config_by_level(self: @T, level: u32) -> ProfileLevelConfig;
    fn get_next_level_profile_config_by_address(
        self: @T, address: ContractAddress,
    ) -> ProfileLevelConfig;
    fn migrate(ref self: T, profiles: Span<Profile>, season_progresses: Span<SeasonProgress>);
}

#[dojo::contract]
pub mod profile_system {
    use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
    use openzeppelin_access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use crate::constants::constants::DEFAULT_NS_BYTE;
    use crate::models::SeasonProgress;
    use crate::store::StoreTrait;
    use super::IJokersProfile;

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

    const WRITER_ROLE: felt252 = selector!("WRITER_ROLE");

    fn dojo_init(ref self: ContractState, owner: ContractAddress) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(WRITER_ROLE, owner);
    }

    #[abi(embed_v0)]
    impl ProfileImpl of IJokersProfile<ContractState> {
        fn create_profile(
            ref self: ContractState, address: ContractAddress, username: ByteArray, avatar_id: u16,
        ) {
            // self.accesscontrol.assert_only_role(WRITER_ROLE);
            let mut store = StoreTrait::new(self.world_default());

            store
                .set_profile(
                    @Profile {
                        address,
                        username,
                        total_xp: 0,
                        xp: 0,
                        level: 0,
                        available_games: 3,
                        max_available_games: 3,
                        daily_streak: 1,
                        banned: false,
                        badges_ids: [].span(),
                        avatar_id,
                    },
                )
        }

        fn add_stats(ref self: ContractState, player_stats: PlayerStats) {
            self.accesscontrol.assert_only_role(WRITER_ROLE);
            self._add_stats(player_stats)
        }

        fn update_avatar(ref self: ContractState, player_address: ContractAddress, avatar_id: u16) {
            self.accesscontrol.assert_only_role(WRITER_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            let mut profile = store.get_profile(player_address);
            profile.avatar_id = avatar_id;
            store.set_profile(@profile);
        }

        fn get_profile(self: @ContractState, player_address: ContractAddress) -> Profile {
            let mut store = StoreTrait::new(self.world_default());
            store.get_profile(player_address)
        }

        fn get_player_stats(self: @ContractState, player_address: ContractAddress) -> PlayerStats {
            let mut store = StoreTrait::new(self.world_default());
            store.get_player_stats(player_address)
        }

        fn get_profile_level_config_by_level(
            self: @ContractState, level: u32,
        ) -> ProfileLevelConfig {
            let mut store = StoreTrait::new(self.world_default());
            store.get_profile_level_config(level)
        }

        fn get_next_level_profile_config_by_address(
            self: @ContractState, address: ContractAddress,
        ) -> ProfileLevelConfig {
            let mut store = StoreTrait::new(self.world_default());
            let profile = store.get_profile(address);
            store.get_profile_level_config(profile.level + 1)
        }

        fn migrate(
            ref self: ContractState,
            profiles: Span<Profile>,
            season_progresses: Span<SeasonProgress>,
        ) {
            assert!(
                profiles.len() == season_progresses.len(),
                "[ProfileSystem] Profiles and season progresses must have the same length",
            );
            // self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());

            for profile in profiles {
                store.set_profile(profile);
            }

            for season_progress in season_progresses {
                store.set_season_progress(season_progress);
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@DEFAULT_NS_BYTE())
        }

        fn _add_stats(self: @ContractState, player_stats: PlayerStats) {
            let mut store = StoreTrait::new(self.world_default());
            let mut current_player_stats = store.get_player_stats(player_stats.address);

            current_player_stats.games_played += player_stats.games_played;
            current_player_stats.games_won += player_stats.games_won;
            current_player_stats.high_card_played += player_stats.high_card_played;
            current_player_stats.pair_played += player_stats.pair_played;
            current_player_stats.two_pair_played += player_stats.two_pair_played;
            current_player_stats.three_of_a_kind_played += player_stats.three_of_a_kind_played;
            current_player_stats.four_of_a_kind_played += player_stats.four_of_a_kind_played;
            current_player_stats.five_of_a_kind_played += player_stats.five_of_a_kind_played;
            current_player_stats.full_house_played += player_stats.full_house_played;
            current_player_stats.flush_played += player_stats.flush_played;
            current_player_stats.straight_played += player_stats.straight_played;
            current_player_stats.straight_flush_played += player_stats.straight_flush_played;
            current_player_stats.royal_flush_played += player_stats.royal_flush_played;

            current_player_stats.loot_boxes_purchased += player_stats.loot_boxes_purchased;
            current_player_stats.cards_purchased += player_stats.cards_purchased;
            current_player_stats.specials_purchased += player_stats.specials_purchased;
            current_player_stats.power_ups_purchased += player_stats.power_ups_purchased;
            current_player_stats.level_ups_purchased += player_stats.level_ups_purchased;
            current_player_stats.modifiers_purchased += player_stats.modifiers_purchased;
            current_player_stats.rerolls_purchased += player_stats.rerolls_purchased;
            current_player_stats.burn_purchased += player_stats.burn_purchased;
            current_player_stats.specials_sold += player_stats.specials_sold;

            store.set_player_stats(current_player_stats);
        }
    }
}
