use jokers_of_neon_lib::random::{Random, RandomTrait};
use crate::constants::constants::PERCENT_SCALE;
use crate::models::{Pack, SeasonContent};

#[generate_trait]
pub impl PackTraitImpl of PackTrait {
    fn open(pack: Pack, season_content: SeasonContent, ref random: Random) -> Span<u32> {
        let mut result = array![];
        for prob in pack.probabilities {
            // Get the index of items based on the probabilities
            // [ [ITEM_1_PROB, ITEM_2_PROB, .., ITEM_X_PROB] ]
            //   ‾‾‾‾‾↑‾‾‾‾‾
            let number = random.get_random_number_zero_indexed(PERCENT_SCALE);
            let index_content = get_index_content(*prob, number);
            let items = *season_content.items.at(index_content);

            // Get the item from the possible items
            // [CARD_1, CARD_2, CARD_3]
            // ‾↑‾
            let number = random.get_random_number_zero_indexed(items.len());
            result.append(*items.at(number));
        }
        result.span()
    }
}

pub fn get_index_content(probs: Span<u32>, number: u32) -> u32 {
    let mut acum = 0;
    let mut result_index = 0;
    for index in 0..probs.len() {
        acum += *probs.at(index);
        if number < acum {
            result_index = index;
            break;
        }
    }
    // This is just a safety check to avoid wrong probabilities
    assert!(
        acum >= number,
        "[PackTrait] - Random number ({}) is greater than the sum of the probabilities ({})",
        number,
        acum,
    );
    result_index
}
