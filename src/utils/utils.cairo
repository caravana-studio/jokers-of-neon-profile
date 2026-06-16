use crate::constants::season_configs::{get_level_xp_data, get_mission_xp_data};

const SECONDS_IN_DAY: u64 = 86400;
const DAY_START_OFFSET: u64 = 21600; // 6 hours (3am Argentina time = 6am UTC)

pub fn get_current_day() -> u64 {
    (starknet::get_block_timestamp() - DAY_START_OFFSET) / SECONDS_IN_DAY
}

pub fn get_mission_xp_configurable(season_id: u32, difficulty: u8, completion_count: u32) -> u32 {
    let config = get_mission_xp_data(season_id, difficulty, completion_count);
    config.xp_reward
}

pub fn get_level_xp_configurable(season_id: u32, level: u32, completion_count: u32) -> u32 {
    let config = get_level_xp_data(season_id, level, completion_count);
    config.xp_reward
}


pub fn get_tier_from_level(level: u32) -> u32 {
    if level >= 1 && level <= 11 {
        1 // Casual
    } else if level >= 12 && level <= 25 {
        2 // Average
    } else if level >= 26 && level <= 32 {
        3 // Hardcore
    } else { // if level >= 33
        4 // Legend
    }
}
