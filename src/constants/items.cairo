use jokers_of_neon_lib::constants::card::{
    ACE_CLUBS_ID, ACE_DIAMONDS_ID, ACE_HEARTS_ID, ACE_SPADES_ID, EIGHT_CLUBS_ID, EIGHT_DIAMONDS_ID,
    EIGHT_HEARTS_ID, EIGHT_SPADES_ID, FIVE_CLUBS_ID, FIVE_DIAMONDS_ID, FIVE_HEARTS_ID,
    FIVE_SPADES_ID, FOUR_CLUBS_ID, FOUR_DIAMONDS_ID, FOUR_HEARTS_ID, FOUR_SPADES_ID, JACK_CLUBS_ID,
    JACK_DIAMONDS_ID, JACK_HEARTS_ID, JACK_SPADES_ID, JOKER_CARD_ID, KING_CLUBS_ID,
    KING_DIAMONDS_ID, KING_HEARTS_ID, KING_SPADES_ID, NEON_ACE_CLUBS_ID, NEON_ACE_DIAMONDS_ID,
    NEON_ACE_HEARTS_ID, NEON_ACE_SPADES_ID, NEON_EIGHT_CLUBS_ID, NEON_EIGHT_DIAMONDS_ID,
    NEON_EIGHT_HEARTS_ID, NEON_EIGHT_SPADES_ID, NEON_FIVE_CLUBS_ID, NEON_FIVE_DIAMONDS_ID,
    NEON_FIVE_HEARTS_ID, NEON_FIVE_SPADES_ID, NEON_FOUR_CLUBS_ID, NEON_FOUR_DIAMONDS_ID,
    NEON_FOUR_HEARTS_ID, NEON_FOUR_SPADES_ID, NEON_JACK_CLUBS_ID, NEON_JACK_DIAMONDS_ID,
    NEON_JACK_HEARTS_ID, NEON_JACK_SPADES_ID, NEON_JOKER_CARD_ID, NEON_KING_CLUBS_ID,
    NEON_KING_DIAMONDS_ID, NEON_KING_HEARTS_ID, NEON_KING_SPADES_ID, NEON_NINE_CLUBS_ID,
    NEON_NINE_DIAMONDS_ID, NEON_NINE_HEARTS_ID, NEON_NINE_SPADES_ID, NEON_QUEEN_CLUBS_ID,
    NEON_QUEEN_DIAMONDS_ID, NEON_QUEEN_HEARTS_ID, NEON_QUEEN_SPADES_ID, NEON_SEVEN_CLUBS_ID,
    NEON_SEVEN_DIAMONDS_ID, NEON_SEVEN_HEARTS_ID, NEON_SEVEN_SPADES_ID, NEON_SIX_CLUBS_ID,
    NEON_SIX_DIAMONDS_ID, NEON_SIX_HEARTS_ID, NEON_SIX_SPADES_ID, NEON_TEN_CLUBS_ID,
    NEON_TEN_DIAMONDS_ID, NEON_TEN_HEARTS_ID, NEON_TEN_SPADES_ID, NEON_THREE_CLUBS_ID,
    NEON_THREE_DIAMONDS_ID, NEON_THREE_HEARTS_ID, NEON_THREE_SPADES_ID, NEON_TWO_CLUBS_ID,
    NEON_TWO_DIAMONDS_ID, NEON_TWO_HEARTS_ID, NEON_TWO_SPADES_ID, NINE_CLUBS_ID, NINE_DIAMONDS_ID,
    NINE_HEARTS_ID, NINE_SPADES_ID, QUEEN_CLUBS_ID, QUEEN_DIAMONDS_ID, QUEEN_HEARTS_ID,
    QUEEN_SPADES_ID, SEVEN_CLUBS_ID, SEVEN_DIAMONDS_ID, SEVEN_HEARTS_ID, SEVEN_SPADES_ID,
    SIX_CLUBS_ID, SIX_DIAMONDS_ID, SIX_HEARTS_ID, SIX_SPADES_ID, TEN_CLUBS_ID, TEN_DIAMONDS_ID,
    TEN_HEARTS_ID, TEN_SPADES_ID, THREE_CLUBS_ID, THREE_DIAMONDS_ID, THREE_HEARTS_ID,
    THREE_SPADES_ID, TWO_CLUBS_ID, TWO_DIAMONDS_ID, TWO_HEARTS_ID, TWO_SPADES_ID,
};
use crate::models::{Item, ItemType};

const NONE: u32 = 0;
const C: u32 = 1;
const B: u32 = 2;
const A: u32 = 3;
const S: u32 = 4;

pub fn TRADITIONAL_CARDS_ITEMS_ALL() -> Span<Item> {
    [
        Item {
            id: 1,
            item_type: ItemType::Traditional,
            content_id: TWO_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 2,
            item_type: ItemType::Traditional,
            content_id: THREE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 3,
            item_type: ItemType::Traditional,
            content_id: FOUR_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 4,
            item_type: ItemType::Traditional,
            content_id: FIVE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 5,
            item_type: ItemType::Traditional,
            content_id: SIX_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 6,
            item_type: ItemType::Traditional,
            content_id: SEVEN_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 7,
            item_type: ItemType::Traditional,
            content_id: EIGHT_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 8,
            item_type: ItemType::Traditional,
            content_id: NINE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 9,
            item_type: ItemType::Traditional,
            content_id: TEN_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 10,
            item_type: ItemType::Traditional,
            content_id: JACK_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 11,
            item_type: ItemType::Traditional,
            content_id: QUEEN_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 12,
            item_type: ItemType::Traditional,
            content_id: KING_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 13,
            item_type: ItemType::Traditional,
            content_id: ACE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 14,
            item_type: ItemType::Traditional,
            content_id: TWO_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 15,
            item_type: ItemType::Traditional,
            content_id: THREE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 16,
            item_type: ItemType::Traditional,
            content_id: FOUR_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 17,
            item_type: ItemType::Traditional,
            content_id: FIVE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 18,
            item_type: ItemType::Traditional,
            content_id: SIX_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 19,
            item_type: ItemType::Traditional,
            content_id: SEVEN_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 20,
            item_type: ItemType::Traditional,
            content_id: EIGHT_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 21,
            item_type: ItemType::Traditional,
            content_id: NINE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 22,
            item_type: ItemType::Traditional,
            content_id: TEN_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 23,
            item_type: ItemType::Traditional,
            content_id: JACK_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 24,
            item_type: ItemType::Traditional,
            content_id: QUEEN_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 25,
            item_type: ItemType::Traditional,
            content_id: KING_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 26,
            item_type: ItemType::Traditional,
            content_id: ACE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 27,
            item_type: ItemType::Traditional,
            content_id: TWO_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 28,
            item_type: ItemType::Traditional,
            content_id: THREE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 29,
            item_type: ItemType::Traditional,
            content_id: FOUR_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 30,
            item_type: ItemType::Traditional,
            content_id: FIVE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 31,
            item_type: ItemType::Traditional,
            content_id: SIX_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 32,
            item_type: ItemType::Traditional,
            content_id: SEVEN_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 33,
            item_type: ItemType::Traditional,
            content_id: EIGHT_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 34,
            item_type: ItemType::Traditional,
            content_id: NINE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 35,
            item_type: ItemType::Traditional,
            content_id: TEN_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 36,
            item_type: ItemType::Traditional,
            content_id: JACK_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 37,
            item_type: ItemType::Traditional,
            content_id: QUEEN_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 38,
            item_type: ItemType::Traditional,
            content_id: KING_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 39,
            item_type: ItemType::Traditional,
            content_id: ACE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 40,
            item_type: ItemType::Traditional,
            content_id: TWO_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 41,
            item_type: ItemType::Traditional,
            content_id: THREE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 42,
            item_type: ItemType::Traditional,
            content_id: FOUR_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 43,
            item_type: ItemType::Traditional,
            content_id: FIVE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 44,
            item_type: ItemType::Traditional,
            content_id: SIX_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 45,
            item_type: ItemType::Traditional,
            content_id: SEVEN_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 46,
            item_type: ItemType::Traditional,
            content_id: EIGHT_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 47,
            item_type: ItemType::Traditional,
            content_id: NINE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 48,
            item_type: ItemType::Traditional,
            content_id: TEN_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 49,
            item_type: ItemType::Traditional,
            content_id: JACK_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 50,
            item_type: ItemType::Traditional,
            content_id: QUEEN_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 51,
            item_type: ItemType::Traditional,
            content_id: KING_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 52,
            item_type: ItemType::Traditional,
            content_id: ACE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
    ]
        .span()
}

pub fn JOKER_CARD_ITEM() -> Item {
    Item {
        id: 53,
        item_type: ItemType::Traditional,
        content_id: JOKER_CARD_ID,
        rarity: C,
        skin_id: 1,
        skin_rarity: NONE,
    }
}

pub fn NEON_CARDS_ITEMS_ALL() -> Span<Item> {
    [
        Item {
            id: 54,
            item_type: ItemType::Neon,
            content_id: NEON_TWO_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 55,
            item_type: ItemType::Neon,
            content_id: NEON_THREE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 56,
            item_type: ItemType::Neon,
            content_id: NEON_FOUR_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 57,
            item_type: ItemType::Neon,
            content_id: NEON_FIVE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 58,
            item_type: ItemType::Neon,
            content_id: NEON_SIX_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 59,
            item_type: ItemType::Neon,
            content_id: NEON_SEVEN_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 60,
            item_type: ItemType::Neon,
            content_id: NEON_EIGHT_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 61,
            item_type: ItemType::Neon,
            content_id: NEON_NINE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 62,
            item_type: ItemType::Neon,
            content_id: NEON_TEN_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 63,
            item_type: ItemType::Neon,
            content_id: NEON_JACK_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 64,
            item_type: ItemType::Neon,
            content_id: NEON_QUEEN_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 65,
            item_type: ItemType::Neon,
            content_id: NEON_KING_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 66,
            item_type: ItemType::Neon,
            content_id: NEON_ACE_CLUBS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 67,
            item_type: ItemType::Neon,
            content_id: NEON_TWO_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 68,
            item_type: ItemType::Neon,
            content_id: NEON_THREE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 69,
            item_type: ItemType::Neon,
            content_id: NEON_FOUR_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 70,
            item_type: ItemType::Neon,
            content_id: NEON_FIVE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 71,
            item_type: ItemType::Neon,
            content_id: NEON_SIX_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 72,
            item_type: ItemType::Neon,
            content_id: NEON_SEVEN_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 73,
            item_type: ItemType::Neon,
            content_id: NEON_EIGHT_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 74,
            item_type: ItemType::Neon,
            content_id: NEON_NINE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 75,
            item_type: ItemType::Neon,
            content_id: NEON_TEN_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 76,
            item_type: ItemType::Neon,
            content_id: NEON_JACK_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 77,
            item_type: ItemType::Neon,
            content_id: NEON_QUEEN_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 78,
            item_type: ItemType::Neon,
            content_id: NEON_KING_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 79,
            item_type: ItemType::Neon,
            content_id: NEON_ACE_DIAMONDS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 80,
            item_type: ItemType::Neon,
            content_id: NEON_TWO_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 81,
            item_type: ItemType::Neon,
            content_id: NEON_THREE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 82,
            item_type: ItemType::Neon,
            content_id: NEON_FOUR_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 83,
            item_type: ItemType::Neon,
            content_id: NEON_FIVE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 84,
            item_type: ItemType::Neon,
            content_id: NEON_SIX_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 85,
            item_type: ItemType::Neon,
            content_id: NEON_SEVEN_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 86,
            item_type: ItemType::Neon,
            content_id: NEON_EIGHT_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 87,
            item_type: ItemType::Neon,
            content_id: NEON_NINE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 88,
            item_type: ItemType::Neon,
            content_id: NEON_TEN_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 89,
            item_type: ItemType::Neon,
            content_id: NEON_JACK_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 90,
            item_type: ItemType::Neon,
            content_id: NEON_QUEEN_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 91,
            item_type: ItemType::Neon,
            content_id: NEON_KING_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 92,
            item_type: ItemType::Neon,
            content_id: NEON_ACE_HEARTS_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 93,
            item_type: ItemType::Neon,
            content_id: NEON_TWO_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 94,
            item_type: ItemType::Neon,
            content_id: NEON_THREE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 95,
            item_type: ItemType::Neon,
            content_id: NEON_FOUR_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 96,
            item_type: ItemType::Neon,
            content_id: NEON_FIVE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 97,
            item_type: ItemType::Neon,
            content_id: NEON_SIX_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 98,
            item_type: ItemType::Neon,
            content_id: NEON_SEVEN_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 99,
            item_type: ItemType::Neon,
            content_id: NEON_EIGHT_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 100,
            item_type: ItemType::Neon,
            content_id: NEON_NINE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 101,
            item_type: ItemType::Neon,
            content_id: NEON_TEN_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 102,
            item_type: ItemType::Neon,
            content_id: NEON_JACK_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 103,
            item_type: ItemType::Neon,
            content_id: NEON_QUEEN_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 104,
            item_type: ItemType::Neon,
            content_id: NEON_KING_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
        Item {
            id: 105,
            item_type: ItemType::Neon,
            content_id: NEON_ACE_SPADES_ID,
            rarity: C,
            skin_id: 1,
            skin_rarity: NONE,
        },
    ]
        .span()
}

pub fn NEON_JOKER_CARD_ITEM() -> Item {
    Item {
        id: 106,
        item_type: ItemType::Neon,
        content_id: NEON_JOKER_CARD_ID,
        rarity: A,
        skin_id: 1,
        skin_rarity: NONE,
    }
}

pub fn SPECIAL_C_ITEMS() -> Span<Item> {
    // [C]
    let FADED_POSTER = Item {
        id: 107,
        item_type: ItemType::Special,
        content_id: 10101,
        rarity: C,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let TAMER_OF_CHANCES = Item {
        id: 108,
        item_type: ItemType::Special,
        content_id: 10102,
        rarity: C,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let BLACKJACK = Item {
        id: 109,
        item_type: ItemType::Special,
        content_id: 10103,
        rarity: C,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let POINT_JUGGLER = Item {
        id: 110,
        item_type: ItemType::Special,
        content_id: 10104,
        rarity: C,
        skin_id: 1,
        skin_rarity: NONE,
    };
    [FADED_POSTER, TAMER_OF_CHANCES, BLACKJACK, POINT_JUGGLER].span()
}

pub fn SPECIAL_B_ITEMS() -> Span<Item> {
    // [B]
    let DECK_COLLECTOR = Item {
        id: 111,
        item_type: ItemType::Special,
        content_id: 10105,
        rarity: B,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let CIRCLE_OF_FORTUNE = Item {
        id: 112,
        item_type: ItemType::Special,
        content_id: 10106,
        rarity: B,
        skin_id: 1,
        skin_rarity: B,
    };
    let HESTIA_BLESSING = Item {
        id: 113,
        item_type: ItemType::Special,
        content_id: 10107,
        rarity: B,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let SUIT_ROULETTE = Item {
        id: 114,
        item_type: ItemType::Special,
        content_id: 10108,
        rarity: B,
        skin_id: 1,
        skin_rarity: NONE,
    };
    [DECK_COLLECTOR, CIRCLE_OF_FORTUNE, HESTIA_BLESSING, SUIT_ROULETTE].span()
}

pub fn SPECIAL_A_ITEMS() -> Span<Item> {
    // [A]
    let HANGED_JOKER = Item {
        id: 115,
        item_type: ItemType::Special,
        content_id: 10109,
        rarity: A,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let SACRIFICE = Item {
        id: 116,
        item_type: ItemType::Special,
        content_id: 10110,
        rarity: A,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let HIGH_ROLLER = Item {
        id: 117,
        item_type: ItemType::Special,
        content_id: 10111,
        rarity: A,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let EFFICIENT_PLAY = Item {
        id: 118,
        item_type: ItemType::Special,
        content_id: 10112,
        rarity: A,
        skin_id: 1,
        skin_rarity: NONE,
    };
    [HANGED_JOKER, SACRIFICE, HIGH_ROLLER, EFFICIENT_PLAY].span()
}

pub fn SPECIAL_S_ITEMS() -> Span<Item> {
    // [S]
    let RAGE_BREAKER = Item {
        id: 119,
        item_type: ItemType::Special,
        content_id: 10113,
        rarity: S,
        skin_id: 1,
        skin_rarity: NONE,
    };
    let BURNING_REWARDS = Item {
        id: 120,
        item_type: ItemType::Special,
        content_id: 10114,
        rarity: S,
        skin_id: 1,
        skin_rarity: NONE,
    };
    [RAGE_BREAKER, BURNING_REWARDS].span()
}

pub fn SPECIAL_SKINS_RARITY_C_ITEMS() -> Span<Item> {
    let POINT_JUGGLER_RARITY_C = Item {
        id: 121,
        item_type: ItemType::Special,
        content_id: 10104,
        rarity: C,
        skin_id: 2,
        skin_rarity: S,
    };

    [POINT_JUGGLER_RARITY_C].span()
}

pub fn SPECIAL_SKINS_RARITY_A_ITEMS() -> Span<Item> {
    let HANGED_JOKER_RARITY_A = Item {
        id: 122,
        item_type: ItemType::Special,
        content_id: 10109,
        rarity: A,
        skin_id: 2,
        skin_rarity: S,
    };
    [HANGED_JOKER_RARITY_A].span()
}

pub fn ALL_ITEMS() -> Array<Item> {
    let mut items = array![];
    for item in TRADITIONAL_CARDS_ITEMS_ALL() {
        items.append(*item);
    }
    items.append(JOKER_CARD_ITEM());

    for item in NEON_CARDS_ITEMS_ALL() {
        items.append(*item);
    }

    items.append(NEON_JOKER_CARD_ITEM());

    for item in SPECIAL_C_ITEMS() {
        items.append(*item);
    }

    for item in SPECIAL_B_ITEMS() {
        items.append(*item);
    }

    for item in SPECIAL_A_ITEMS() {
        items.append(*item);
    }

    for item in SPECIAL_S_ITEMS() {
        items.append(*item);
    }

    for item in SPECIAL_SKINS_RARITY_C_ITEMS() {
        items.append(*item);
    }

    for item in SPECIAL_SKINS_RARITY_A_ITEMS() {
        items.append(*item);
    }
    items
}
