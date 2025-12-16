use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
use starknet::ContractAddress;
use crate::models::{GameData, PokerHandData, RoundData, SeasonProgress};

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

    fn set_game_data(ref self: T, game_data: GameData);
    fn set_round_data(ref self: T, round_data: RoundData);
    fn add_poker_hand_data(ref self: T, poker_hand_data: PokerHandData);
    fn migrate(ref self: T, profiles: Span<Profile>, season_progresses: Span<SeasonProgress>);
    fn add_claimable_pack(ref self: T, address: ContractAddress, pack_id: u32);
    fn remove_claimable_pack(ref self: T, address: ContractAddress, pack_id: u32);
    fn claim_packs(ref self: T, address: ContractAddress);
}

#[dojo::contract]
pub mod profile_system {
    use dojo::world::WorldStorage;
    use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::constants::constants::DEFAULT_NS_BYTE;
    use crate::models::{GameData, PokerHandData, RoundData, SeasonProgress};
    use crate::store::{Store, StoreTrait};
    use crate::systems::permission_system::IPermissionSystemDispatcherTrait;
    use crate::utils::systems::SystemsTrait;
    use super::IJokersProfile;

    #[abi(embed_v0)]
    impl ProfileImpl of IJokersProfile<ContractState> {
        fn create_profile(
            ref self: ContractState, address: ContractAddress, username: ByteArray, avatar_id: u16,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

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
                        claimable_packs: [].span(),
                    },
                )
        }

        fn add_stats(ref self: ContractState, player_stats: PlayerStats) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            self._add_stats(player_stats)
        }

        fn update_avatar(ref self: ContractState, player_address: ContractAddress, avatar_id: u16) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let mut profile = store.get_profile(player_address);
            profile.avatar_id = avatar_id;
            store.set_profile(@profile);
        }

        fn get_profile(self: @ContractState, player_address: ContractAddress) -> Profile {
            let mut store = self.create_store();
            store.get_profile(player_address)
        }

        fn get_player_stats(self: @ContractState, player_address: ContractAddress) -> PlayerStats {
            let mut store = self.create_store();
            store.get_player_stats(player_address)
        }

        fn get_profile_level_config_by_level(
            self: @ContractState, level: u32,
        ) -> ProfileLevelConfig {
            let mut store = self.create_store();
            store.get_profile_level_config(level)
        }

        fn get_next_level_profile_config_by_address(
            self: @ContractState, address: ContractAddress,
        ) -> ProfileLevelConfig {
            let mut store = self.create_store();
            let profile = store.get_profile(address);
            store.get_profile_level_config(profile.level + 1)
        }

        fn migrate(
            ref self: ContractState,
            profiles: Span<Profile>,
            season_progresses: Span<SeasonProgress>,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            assert!(
                profiles.len() == season_progresses.len(),
                "[ProfileSystem] Profiles and season progresses must have the same length",
            );

            for profile in profiles {
                store.set_profile(profile);
            }

            for season_progress in season_progresses {
                store.set_season_progress(season_progress);
            }
        }

        fn set_game_data(ref self: ContractState, game_data: GameData) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());
            store.set_game_data(game_data);
        }

        fn set_round_data(ref self: ContractState, round_data: RoundData) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());
            store.set_round_data(round_data);
        }

        fn add_poker_hand_data(ref self: ContractState, poker_hand_data: PokerHandData) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());
            let mut poker_hand_data = store.get_poker_hand_data(poker_hand_data.player_address);

            poker_hand_data.royal_flush += poker_hand_data.royal_flush;
            poker_hand_data.straight_flush += poker_hand_data.straight_flush;
            poker_hand_data.five_of_a_kind += poker_hand_data.five_of_a_kind;
            poker_hand_data.four_of_a_kind += poker_hand_data.four_of_a_kind;
            poker_hand_data.full_house += poker_hand_data.full_house;
            poker_hand_data.straight += poker_hand_data.straight;
            poker_hand_data.flush += poker_hand_data.flush;
            poker_hand_data.three_of_a_kind += poker_hand_data.three_of_a_kind;
            poker_hand_data.two_pair += poker_hand_data.two_pair;
            poker_hand_data.one_pair += poker_hand_data.one_pair;
            poker_hand_data.high_card += poker_hand_data.high_card;
            store.set_poker_hand_data(poker_hand_data);
        }

        fn add_claimable_pack(ref self: ContractState, address: ContractAddress, pack_id: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let mut profile = store.get_profile(address);

            let mut new_packs: Array<u32> = array![];
            for pack in profile.claimable_packs {
                new_packs.append(*pack);
            }
            new_packs.append(pack_id);

            profile.claimable_packs = new_packs.span();
            store.set_profile(@profile);
        }

        fn remove_claimable_pack(ref self: ContractState, address: ContractAddress, pack_id: u32) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let mut profile = store.get_profile(address);

            let mut new_packs: Array<u32> = array![];
            let mut found = false;
            for pack in profile.claimable_packs {
                if *pack == pack_id && !found {
                    found = true;
                } else {
                    new_packs.append(*pack);
                }
            }

            assert(found, 'Pack not found');

            profile.claimable_packs = new_packs.span();
            store.set_profile(@profile);
        }

        fn claim_packs(ref self: ContractState, address: ContractAddress) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let mut profile = store.get_profile(address);

            profile.claimable_packs = [].span();
            store.set_profile(@profile);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn create_store(self: @ContractState) -> Store {
            StoreTrait::new(self.create_world())
        }

        fn create_world(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS_BYTE())
        }

        fn _add_stats(self: @ContractState, player_stats: PlayerStats) {
            let mut store = self.create_store();
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
