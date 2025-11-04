use crate::constants::constants::PERCENT_SCALE;
use crate::models::Pack;

pub const BASIC_PACK_ID: u32 = 1;
pub const ADVANCED_PACK_ID: u32 = 2;
pub const EPIC_PACK_ID: u32 = 3;
pub const LEGENDARY_PACK_ID: u32 = 4;
pub const COLLECTORS_PACK_ID: u32 = 5;
pub const COLLECTORS_XL_PACK_ID: u32 = 6;

pub fn BASIC_PACK() -> Pack {
    //       Traditional	Joker		Neon	Neon Joker	C	   B	  A	      S     Skin 1   Skin 2
    // Item 1	96,0%	    2,0%	    2,0%	   0,0%	   0,0%	  0,0%	 0,0%	 0,0%   0,0%    0,0%
    // Item 2	55,0%	    2,0%	    42,9%	   0,1%	   0,0%	  0,0%	 0,0%	 0,0%   0,0%    0,0%
    // Item 3	0,0%	    5,0%	    83,0%	   2,0%	   8,0%	  1,9%	 0,1%	 0,0%   0,0%    0,0%

    let item_1 = [9600, 200, 200, 0, 0, 0, 0, 0, 0, 0].span();
    let item_2 = [5500, 200, 4290, 10, 0, 0, 0, 0, 0, 0].span();
    let item_3 = [0, 500, 8300, 200, 800, 190, 10, 0, 0, 0].span();

    assert!(
        10 == item_1.len() && item_1.len() == item_2.len() && item_2.len() == item_3.len(),
        "[PackMinter] - Basic Pack invalid probabilities",
    );
    let probabilities = [item_1, item_2, item_3].span();
    for items_probability in probabilities {
        let mut sum: u32 = 0;
        for probability in items_probability {
            sum += *probability;
        }
        assert!(
            sum == PERCENT_SCALE,
            "[PackMinter] - Some item probability {:?} is {} (should be PERCENT_SCALE)",
            items_probability,
            sum,
        );
    }
    Pack { id: BASIC_PACK_ID, season_id: 1, name: "Basic", probabilities }
}

pub fn ADVANCED_PACK() -> Pack {
    //       Traditional	Joker		Neon	Neon Joker	C	   B	  A	      S     Skin 1   Skin 2
    // Item 1	96,0%	    2,0%	    2,0%	   0,0%	   0,0%	  0,0%	 0,0%	 0,0%    0,0%    0,0%
    // Item 2	0,0%	    5,0%	    83,0%	   2,0%	   8,0%	  1,9%	 0,1%	 0,0%    0,0%    0,0%
    // Item 3	0,0%	    0,0%	    48,0%	   2,0%	   40,0%  7,0%	 2,9%	 0,1%    0,0%    0,0%

    let item_1 = [9600, 200, 200, 0, 0, 0, 0, 0, 0, 0].span();
    let item_2 = [0, 500, 8300, 200, 800, 190, 10, 0, 0, 0].span();
    let item_3 = [0, 0, 4800, 200, 4000, 700, 290, 10, 0, 0].span();

    assert!(
        10 == item_1.len() && item_1.len() == item_2.len() && item_2.len() == item_3.len(),
        "[PackMinter] - Advanced Pack invalid probabilities",
    );
    let probabilities = [item_1, item_2, item_3].span();
    for items_probability in probabilities {
        let mut sum: u32 = 0;
        for probability in items_probability {
            sum += *probability;
        }
        assert!(
            sum == PERCENT_SCALE,
            "[PackMinter] - Some item probability {:?} is {} (should be PERCENT_SCALE)",
            items_probability,
            sum,
        );
    }
    Pack { id: ADVANCED_PACK_ID, season_id: 1, name: "Advanced", probabilities }
}

pub fn EPIC_PACK() -> Pack {
    //        Traditional	Joker	Neon	Neon Joker	 C	     B	     A	     S     Skin 1   Skin 2
    // Item 1	96,0%	    2,0%    2,0%	   0,0%	    0,0%	0,0%	0,0%	0,0%    0,0%    0,0%
    // Item 2	60,0%	    2,0%    37,9%	   0,1%	    0,0%	0,0%	0,0%	0,0%    0,0%    0,0%
    // Item 3	0,0%	    0,0%    76,9%	   2,0%	    15,0%	5,0%	1,0%	0,1%    0,0%    0,0%
    // Item 4	0,0%	    0,0%    21,0%	   4,0%	    47,0%	15,0%	10,0%	3,0%    0,0%    0,0%

    let item_1 = [9600, 200, 200, 0, 0, 0, 0, 0, 0, 0].span();
    let item_2 = [6000, 200, 3790, 10, 0, 0, 0, 0, 0, 0].span();
    let item_3 = [0, 0, 7690, 200, 1500, 500, 100, 10, 0, 0].span();
    let item_4 = [0, 0, 2100, 400, 4700, 1500, 1000, 300, 0, 0].span();

    assert!(
        10 == item_1.len()
            && item_1.len() == item_2.len()
            && item_2.len() == item_3.len()
            && item_3.len() == item_4.len(),
        "[PackMinter] - Epic Pack invalid probabilities",
    );
    let probabilities = [item_1, item_2, item_3, item_4].span();
    for items_probability in probabilities {
        let mut sum: u32 = 0;
        for probability in items_probability {
            sum += *probability;
        }
        assert!(
            sum == PERCENT_SCALE,
            "[PackMinter] - Some item probability {:?} is {} (should be PERCENT_SCALE)",
            items_probability,
            sum,
        );
    }
    Pack { id: EPIC_PACK_ID, season_id: 1, name: "Epic", probabilities }
}

pub fn LEGENDARY_PACK() -> Pack {
    //        Traditional	Joker		Neon	Neon Joker	 C	     B	     A	     S      Skin 1   Skin 2
    // Item 1	96,0%	    2,0%	    2,0%	   0,0%	    0,0%	0,0%	0,0%	0,0%    0,0%    0,0%
    // Item 2	55,0%	    2,0%	    42,9%	   0,1%	    0,0%	0,0%	0,0%	0,0%    0,0%    0,0%
    // Item 3	0,0%	    0,0%	    48,0%	   2,0%	    40,0%	7,0%	2,9%	0,1%    0,0%    0,0%
    // Item 4	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	60,0%	30,0%	10,0%   0,0%    0,0%

    let item_1 = [9600, 200, 200, 0, 0, 0, 0, 0, 0, 0].span();
    let item_2 = [5500, 200, 4290, 10, 0, 0, 0, 0, 0, 0].span();
    let item_3 = [0, 0, 4800, 200, 4000, 700, 290, 10, 0, 0].span();
    let item_4 = [0, 0, 0, 0, 0, 6000, 3000, 1000, 0, 0].span();
    assert!(
        10 == item_1.len()
            && item_1.len() == item_2.len()
            && item_2.len() == item_3.len()
            && item_3.len() == item_4.len(),
        "[PackMinter] - Legendary Pack invalid probabilities",
    );
    let probabilities = [item_1, item_2, item_3, item_4].span();
    for items_probability in probabilities {
        let mut sum: u32 = 0;
        for probability in items_probability {
            sum += *probability;
        }
        assert!(
            sum == PERCENT_SCALE,
            "[PackMinter] - Some item probability {:?} is {} (should be PERCENT_SCALE)",
            items_probability,
            sum,
        );
    }
    Pack { id: LEGENDARY_PACK_ID, season_id: 1, name: "Legendary", probabilities }
}

pub fn COLLECTORS_PACK() -> Pack {
    //        Traditional	Joker		Neon	Neon Joker	 C	     B	     A	     S     Skin 1   Skin 2
    // Item 1	50,0%	    20,0%	    10,0%	   10,0%    5,0%	5,0%	0,0%	0,0%    0,0%    0,0%
    // Item 2	0,0%	    30,0%	    20,0%	   20,0%    10,0%	10,0%	5,0%	5,0%    0,0%    0,0%
    // Item 3	0,0%	    0,0%	    20,0%	   30,0%    10,0%	20,0%	10,0%	10,0%   0,0%    0,0%
    // Item 4	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	60,0%	30,0%	10,0%   0,0%    0,0%
    // Item 5	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	0,0%	0,0%	0,0%    70,0%    30,0%

    let item_1 = [5000, 2000, 1000, 1000, 500, 500, 0, 0, 0, 0].span();
    let item_2 = [0, 3000, 2000, 2000, 1000, 1000, 500, 500, 0, 0].span();
    let item_3 = [0, 0, 2000, 3000, 1000, 2000, 1000, 1000, 0, 0].span();
    let item_4 = [0, 0, 0, 0, 0, 6000, 3000, 1000, 0, 0].span();
    let item_5 = [0, 0, 0, 0, 0, 0, 0, 0, 7000, 3000].span();
    assert!(
        10 == item_1.len()
            && item_1.len() == item_2.len()
            && item_2.len() == item_3.len()
            && item_3.len() == item_4.len()
            && item_4.len() == item_5.len(),
        "[PackMinter] - Collectors Pack invalid probabilities",
    );
    let probabilities = [item_1, item_2, item_3, item_4, item_5].span();
    for items_probability in probabilities {
        let mut sum: u32 = 0;
        for probability in items_probability {
            sum += *probability;
        }
        assert!(
            sum == PERCENT_SCALE,
            "[PackMinter] - Some item probability {:?} is {} (should be PERCENT_SCALE)",
            items_probability,
            sum,
        );
    }
    Pack { id: COLLECTORS_PACK_ID, season_id: 1, name: "Collectors", probabilities }
}

pub fn COLLECTORS_XL_PACK() -> Pack {
    //        Traditional	Joker		Neon	Neon Joker	 C	     B	     A	     S     Skin 1   Skin 2
    // Item 1	50,0%	    20,0%	    10,0%	   10,0%    5,0%	5,0%	0,0%	0,0%    0,0%    0,0%
    // Item 2	0,0%	    30,0%	    20,0%	   20,0%    10,0%	10,0%	5,0%	5,0%    0,0%    0,0%
    // Item 3	0,0%	    30,0%	    20,0%	   20,0%    10,0%	10,0%	5,0%	5,0%    0,0%    0,0%
    // Item 4	0,0%	    0,0%	    20,0%	   30,0%    10,0%	20,0%	10,0%	10,0%   0,0%    0,0%
    // Item 5	0,0%	    0,0%	    20,0%	   30,0%    10,0%	20,0%	10,0%	10,0%   0,0%    0,0%
    // Item 6	0,0%	    0,0%	    20,0%	   30,0%    10,0%	20,0%	10,0%	10,0%   0,0%    0,0%
    // Item 7	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	60,0%	30,0%	10,0%   0,0%    0,0%
    // Item 8	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	60,0%	30,0%	10,0%   0,0%    0,0%
    // Item 9	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	0,0%	0,0%	0,0%    70,0%   30,0%
    // Item 10	0,0%	    0,0%	    0,0%	   0,0%	    0,0%	0,0%	0,0%	0,0%    70,0%   30,0%

    let item_1 = [5000, 2000, 1000, 1000, 500, 500, 0, 0, 0, 0].span();
    let item_2 = [0, 3000, 2000, 2000, 1000, 1000, 500, 500, 0, 0].span();
    let item_3 = [0, 3000, 2000, 2000, 1000, 1000, 500, 500, 0, 0].span();
    let item_4 = [0, 0, 2000, 3000, 1000, 2000, 1000, 1000, 0, 0].span();
    let item_5 = [0, 0, 2000, 3000, 1000, 2000, 1000, 1000, 0, 0].span();
    let item_6 = [0, 0, 0, 0, 0, 6000, 3000, 1000, 0, 0].span();
    let item_7 = [0, 0, 0, 0, 0, 6000, 3000, 1000, 0, 0].span();
    let item_8 = [0, 0, 0, 0, 0, 6000, 3000, 1000, 0, 0].span();
    let item_9 = [0, 0, 0, 0, 0, 0, 0, 0, 7000, 3000].span();
    let item_10 = [0, 0, 0, 0, 0, 0, 0, 0, 7000, 3000].span();

    assert!(
        10 == item_1.len()
            && item_1.len() == item_2.len()
            && item_2.len() == item_3.len()
            && item_3.len() == item_4.len()
            && item_4.len() == item_5.len()
            && item_5.len() == item_6.len()
            && item_6.len() == item_7.len()
            && item_7.len() == item_8.len()
            && item_8.len() == item_9.len()
            && item_9.len() == item_10.len(),
        "[PackMinter] - Collectors XL Pack invalid probabilities",
    );

    let probabilities = [
        item_1, item_2, item_3, item_4, item_5, item_6, item_7, item_8, item_9, item_10,
    ]
        .span();
    for items_probability in probabilities {
        let mut sum: u32 = 0;
        for probability in items_probability {
            sum += *probability;
        }
        assert!(
            sum == PERCENT_SCALE,
            "[PackMinter] - Some item probability {:?} is {} (should be PERCENT_SCALE)",
            items_probability,
            sum,
        );
    }
    Pack { id: COLLECTORS_XL_PACK_ID, season_id: 1, name: "Collectors XL", probabilities }
}
