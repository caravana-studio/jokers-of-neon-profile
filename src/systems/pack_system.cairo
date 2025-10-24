use crate::models::{Item, Pack, SeasonContent};

#[starknet::interface]
pub trait IPackMinter<T> {
    fn mint(ref self: T, recipient: starknet::ContractAddress, pack_id: u32);
    fn add_pack(ref self: T, pack: Pack);
    fn init_season_content(ref self: T);
    fn get_available_packs(self: @T) -> Array<Pack>;
    fn get_available_items(self: @T) -> Array<Item>;
    fn get_season_content(self: @T) -> SeasonContent;
}

#[starknet::interface]
pub trait INFTCardSystem<T> {
    fn mint_special_card(
        ref self: T,
        recipient: starknet::ContractAddress,
        special_id: u32,
        marketable: bool,
        rarity: u32,
        skin_id: u32,
        skin_rarity: u32,
        quality: u32,
    );
    fn mint_card(
        ref self: T,
        recipient: starknet::ContractAddress,
        card_id: u32,
        marketable: bool,
        skin_id: u32,
        skin_rarity: u32,
        quality: u32,
    );
}

#[dojo::contract]
pub mod pack_system {
    use dojo::event::EventStorage;
    use jokers_of_neon_lib::random::RandomTrait;
    use openzeppelin_access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use crate::constants::constants::{DEFAULT_NS_BYTE, MOD_ID, NFT_MANAGER_KEY};
    use crate::constants::items::{
        ALL_ITEMS, JOKER_CARD_ITEM, NEON_CARDS_ITEMS_ALL, NEON_JOKER_CARD_ITEM, SPECIAL_A_ITEMS,
        SPECIAL_B_ITEMS, SPECIAL_C_ITEMS, SPECIAL_SKINS_RARITY_A_ITEMS,
        SPECIAL_SKINS_RARITY_C_ITEMS, SPECIAL_S_ITEMS, TRADITIONAL_CARDS_ITEMS_ALL,
    };
    use crate::constants::packs::{
        ADVANCED_PACK, BASIC_PACK, COLLECTORS_PACK, COLLECTORS_XL_PACK, EPIC_PACK, LEGENDARY_PACK,
    };
    use crate::models::{CardMintedEvent, Item, ItemType, NFTManager, Pack, SeasonContent};
    use crate::store::StoreTrait;
    use crate::utils::pack::PackTrait;
    use super::{INFTCardSystemDispatcher, INFTCardSystemDispatcherTrait, IPackMinter};

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");
    const SEASON_ID: u32 = 1;

    // External
    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;

    // Internal
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }

    fn dojo_init(
        ref self: ContractState,
        owner: ContractAddress,
        minter: ContractAddress,
        nft_address: ContractAddress,
    ) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(MINTER_ROLE, minter);

        let mut store = StoreTrait::new(self.world_default());
        store.set_nft_manager(NFTManager { key: NFT_MANAGER_KEY(), address: nft_address });
    }

    #[abi(embed_v0)]
    impl PackMinterImpl of IPackMinter<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, pack_id: u32) {
            let mut store = StoreTrait::new(self.world_default());
            self.accesscontrol.assert_only_role(MINTER_ROLE);

            let pack = store.get_pack(pack_id);
            let season_content = store.get_season_content(pack.season_id);
            let mut random = RandomTrait::create_random_instance(MOD_ID());
            let result = PackTrait::open(pack, season_content, ref random);

            let cards_nfts = INFTCardSystemDispatcher {
                contract_address: store.get_nft_manager().address,
            };
            for item_id in result {
                let item = store.get_item(*item_id);
                let quality = random.get_random_number(10);
                match item.item_type {
                    ItemType::Traditional |
                    ItemType::Neon => {
                        cards_nfts
                            .mint_card(
                                recipient,
                                card_id: item.content_id,
                                marketable: true,
                                skin_id: item.skin_id,
                                skin_rarity: item.skin_rarity,
                                quality: quality,
                            );

                        store
                            .world
                            .emit_event(
                                @CardMintedEvent {
                                    recipient,
                                    item: item,
                                    marketable: true,
                                    rarity: item.rarity,
                                    skin_id: item.skin_id,
                                    skin_rarity: item.skin_rarity,
                                    quality,
                                },
                            );
                    },
                    ItemType::Special |
                    ItemType::Skin => {
                        cards_nfts
                            .mint_special_card(
                                recipient,
                                special_id: item.content_id,
                                marketable: true,
                                rarity: item.rarity,
                                skin_id: item.skin_id,
                                skin_rarity: item.skin_rarity,
                                quality: quality,
                            );

                        store
                            .world
                            .emit_event(
                                @CardMintedEvent {
                                    recipient,
                                    item: item,
                                    marketable: true,
                                    rarity: item.rarity,
                                    skin_id: item.skin_id,
                                    skin_rarity: item.skin_rarity,
                                    quality,
                                },
                            );
                    },
                    ItemType::None => {},
                }
            }
        }

        fn add_pack(ref self: ContractState, pack: Pack) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let mut store = StoreTrait::new(self.world_default());
            store.set_pack(pack);
        }

        fn init_season_content(ref self: ContractState) {
            let mut store = StoreTrait::new(self.world_default());
            self.accesscontrol.assert_only_role(MINTER_ROLE);

            let mut season_content = store.get_season_content(SEASON_ID);
            assert!(
                season_content.initialized, "[PackMinter] - Season content already initialized",
            );

            self.init_season_1_packs();
            self.init_season_1_items();

            season_content.initialized = true;
            store.set_season_content(season_content);
        }

        fn get_available_packs(self: @ContractState) -> Array<Pack> {
            array![
                BASIC_PACK(), ADVANCED_PACK(), EPIC_PACK(), LEGENDARY_PACK(), COLLECTORS_PACK(),
                COLLECTORS_XL_PACK(),
            ]
        }

        fn get_season_content(self: @ContractState) -> SeasonContent {
            let mut store = StoreTrait::new(self.world_default());
            store.get_season_content(SEASON_ID)
        }

        fn get_available_items(self: @ContractState) -> Array<Item> {
            ALL_ITEMS()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@DEFAULT_NS_BYTE())
        }

        fn init_season_1_packs(ref self: ContractState) {
            self.add_pack(BASIC_PACK());
            self.add_pack(ADVANCED_PACK());
            self.add_pack(EPIC_PACK());
            self.add_pack(LEGENDARY_PACK());
            self.add_pack(COLLECTORS_PACK());
            self.add_pack(COLLECTORS_XL_PACK());
        }

        fn init_season_1_items(ref self: ContractState) {
            let mut store = StoreTrait::new(self.world_default());

            let mut traditional = array![];
            for item in TRADITIONAL_CARDS_ITEMS_ALL() {
                store.set_item(*item);
                traditional.append(*item.id);
            }

            let mut joker = array![];
            store.set_item(JOKER_CARD_ITEM());
            joker.append(JOKER_CARD_ITEM().id);

            let mut neon = array![];
            for item in NEON_CARDS_ITEMS_ALL() {
                store.set_item(*item);
                neon.append(*item.id);
            }

            let mut neon_joker = array![];
            store.set_item(NEON_JOKER_CARD_ITEM());
            neon_joker.append(NEON_JOKER_CARD_ITEM().id);

            let mut c_items = array![];
            for item in SPECIAL_C_ITEMS() {
                store.set_item(*item);
                c_items.append(*item.id);
            }

            let mut b_items = array![];
            for item in SPECIAL_B_ITEMS() {
                store.set_item(*item);
                b_items.append(*item.id);
            }

            let mut a_items = array![];
            for item in SPECIAL_A_ITEMS() {
                store.set_item(*item);
                a_items.append(*item.id);
            }

            let mut s_items = array![];
            for item in SPECIAL_S_ITEMS() {
                store.set_item(*item);
                s_items.append(*item.id);
            }

            let mut skins_category_1 = array![];
            for item in SPECIAL_SKINS_RARITY_C_ITEMS() {
                store.set_item(*item);
                skins_category_1.append(*item.id);
            }

            let mut skins_category_2 = array![];
            for item in SPECIAL_SKINS_RARITY_A_ITEMS() {
                store.set_item(*item);
                skins_category_2.append(*item.id);
            }

            store
                .set_season_content(
                    SeasonContent {
                        season_id: SEASON_ID,
                        initialized: true,
                        items: [
                            traditional.span(), joker.span(), neon.span(), neon_joker.span(),
                            c_items.span(), b_items.span(), a_items.span(), s_items.span(),
                            skins_category_1.span(), skins_category_2.span(),
                        ]
                            .span(),
                    },
                );
        }
    }
}
