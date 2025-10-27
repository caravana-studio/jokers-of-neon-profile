mod pack_system {
    use jokers_of_neon_lib::random::RandomTrait;
    use crate::constants::items::{
        JOKER_CARD_ITEM, NEON_CARDS_ITEMS_ALL, NEON_JOKER_CARD_ITEM, SPECIAL_A_ITEMS,
        SPECIAL_B_ITEMS, SPECIAL_C_ITEMS, SPECIAL_SKINS_RARITY_A_ITEMS,
        SPECIAL_SKINS_RARITY_C_ITEMS, SPECIAL_S_ITEMS, TRADITIONAL_CARDS_ITEMS_ALL,
    };
    use crate::constants::packs::{
        ADVANCED_PACK, BASIC_PACK, COLLECTORS_PACK, COLLECTORS_XL_PACK, EPIC_PACK, LEGENDARY_PACK,
    };
    use crate::models::SeasonContent;
    use crate::utils::pack::PackTrait;

    const SEASON_ID: u32 = 1;
    #[test]
    fn test_open() {
        println!("[PackTrait::open] running..");
        basic_pack();
        advanced_pack();
        epic_pack();
        legendary_pack();
        collectors_pack();
        collectors_xl_pack();
    }

    fn basic_pack() {
        println!("[BASIC PACK] -------------------------");
        let packs_number = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        let mut random = RandomTrait::create_random_instance('BASIC PACK');
        for i in packs_number {
            let result = PackTrait::open(BASIC_PACK(), SEASON_CONTENT(), ref random);
            println!("Pack {} - {:?}", i, result);
        }
    }

    fn advanced_pack() {
        println!("[ADVANCED PACK] -------------------------");
        let packs_number = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        let mut random = RandomTrait::create_random_instance('ADVANCED PACK');
        for i in packs_number {
            let result = PackTrait::open(ADVANCED_PACK(), SEASON_CONTENT(), ref random);
            println!("Pack {} - {:?}", i, result);
        }
    }

    fn epic_pack() {
        println!("[EPIC PACK] -------------------------");
        let packs_number = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        let mut random = RandomTrait::create_random_instance('EPIC PACK');
        for i in packs_number {
            let result = PackTrait::open(EPIC_PACK(), SEASON_CONTENT(), ref random);
            println!("Pack {} - {:?}", i, result);
        }
    }

    fn legendary_pack() {
        println!("[LEGENDARY PACK] -------------------------");
        let packs_number = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        let mut random = RandomTrait::create_random_instance('LEGENDARY PACK');
        for i in packs_number {
            let result = PackTrait::open(LEGENDARY_PACK(), SEASON_CONTENT(), ref random);
            println!("Pack {} - {:?}", i, result);
        }
    }

    fn collectors_pack() {
        println!("[COLLECTORS PACK] -------------------------");
        let packs_number = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        let mut random = RandomTrait::create_random_instance('COLLECTORS PACK');
        for i in packs_number {
            let result = PackTrait::open(COLLECTORS_PACK(), SEASON_CONTENT(), ref random);
            println!("Pack {} - {:?}", i, result);
        }
    }

    fn collectors_xl_pack() {
        println!("[COLLECTORS XL PACK] -------------------------");
        let packs_number = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        let mut random = RandomTrait::create_random_instance('COLLECTORS XL PACK');
        for i in packs_number {
            let result = PackTrait::open(COLLECTORS_XL_PACK(), SEASON_CONTENT(), ref random);
            println!("Pack {} - {:?}", i, result);
        }
    }

    fn SEASON_CONTENT() -> SeasonContent {
        let mut traditional = array![];
        for item in TRADITIONAL_CARDS_ITEMS_ALL() {
            traditional.append(*item.id);
        }

        let mut joker = array![];
        joker.append(JOKER_CARD_ITEM().id);

        let mut neon = array![];
        for item in NEON_CARDS_ITEMS_ALL() {
            neon.append(*item.id);
        }

        let mut neon_joker = array![];
        neon_joker.append(NEON_JOKER_CARD_ITEM().id);

        let mut c_items = array![];
        for item in SPECIAL_C_ITEMS() {
            c_items.append(*item.id);
        }

        let mut b_items = array![];
        for item in SPECIAL_B_ITEMS() {
            b_items.append(*item.id);
        }

        let mut a_items = array![];
        for item in SPECIAL_A_ITEMS() {
            a_items.append(*item.id);
        }

        let mut s_items = array![];
        for item in SPECIAL_S_ITEMS() {
            s_items.append(*item.id);
        }

        let mut skins_rarity_c = array![];
        for item in SPECIAL_SKINS_RARITY_C_ITEMS() {
            skins_rarity_c.append(*item.id);
        }

        let mut skins_rarity_a = array![];
        for item in SPECIAL_SKINS_RARITY_A_ITEMS() {
            skins_rarity_a.append(*item.id);
        }

        SeasonContent {
            season_id: SEASON_ID,
            items: [
                traditional.span(), joker.span(), neon.span(), neon_joker.span(), c_items.span(),
                b_items.span(), a_items.span(), s_items.span(), skins_rarity_c.span(),
                skins_rarity_a.span(),
            ]
                .span(),
            initialized: true,
        }
    }
}
