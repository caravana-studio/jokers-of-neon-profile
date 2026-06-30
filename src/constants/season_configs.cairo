use crate::constants::constants::STREAK_PROTECTOR_REWARD_ID;
use crate::constants::packs::{
    ADVANCED_SEASON_4_PACK_ID, EPIC_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID,
};
use crate::models::{LevelXPConfig, MissionXPConfig, SeasonLevelConfig};

pub fn get_season_level_data(season_id: u32, level: u32) -> SeasonLevelConfig {
    match season_id {
        4 => get_season_4_level_data(season_id, level),
        _ => SeasonLevelConfig {
            season_id, level, required_xp: 0, free_rewards: [].span(), premium_rewards: [].span(),
        },
    }
}

pub fn get_mission_xp_data(
    season_id: u32, difficulty: u8, completion_count: u32,
) -> MissionXPConfig {
    match season_id {
        4 => get_season_4_mission_xp(season_id, difficulty, completion_count),
        _ => MissionXPConfig { season_id, difficulty, completion_count, xp_reward: 0 },
    }
}

pub fn get_level_xp_data(season_id: u32, level: u32, completion_count: u32) -> LevelXPConfig {
    match season_id {
        4 => get_season_4_level_xp(season_id, level, completion_count),
        _ => LevelXPConfig { season_id, level, completion_count, xp_reward: 0 },
    }
}

// ============================================================
// Season 4
// ============================================================

fn get_season_4_level_data(season_id: u32, level: u32) -> SeasonLevelConfig {
    match level {
        // Casual (Tier 1) - Levels 1-11
        1 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 25,
            free_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
        },
        2 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 50,
            free_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        3 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 75,
            free_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
            premium_rewards: [].span(),
        },
        4 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 100,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        5 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 150,
            free_rewards: [EPIC_SEASON_4_PACK_ID].span(),
            premium_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
        },
        6 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 200,
            free_rewards: [].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        7 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 300,
            free_rewards: [].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
        },
        8 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 400,
            free_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        9 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 500,
            free_rewards: [].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        10 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 600,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [].span(),
        },
        11 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 700,
            free_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
            premium_rewards: [].span(),
        },
        // Average (Tier 2) - Levels 12-25
        12 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 800,
            free_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        13 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 900,
            free_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
            premium_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
        },
        14 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        15 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1100,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        16 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1200,
            free_rewards: [].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
        },
        17 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1300,
            free_rewards: [].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        18 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1400,
            free_rewards: [EPIC_SEASON_4_PACK_ID].span(),
            premium_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
        },
        19 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1500,
            free_rewards: [].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
        },
        20 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1600,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        21 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1700,
            free_rewards: [].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
        },
        22 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1800,
            free_rewards: [].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        23 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 1900,
            free_rewards: [].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
        },
        24 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
        },
        25 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2100,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        // Hardcore (Tier 3) - Levels 26-32
        26 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2200,
            free_rewards: [ADVANCED_SEASON_4_PACK_ID].span(),
            premium_rewards: [].span(),
        },
        27 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2300,
            free_rewards: [STREAK_PROTECTOR_REWARD_ID].span(),
            premium_rewards: [ADVANCED_SEASON_4_PACK_ID, EPIC_SEASON_4_PACK_ID].span(),
        },
        28 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2400,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        29 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2500,
            free_rewards: [EPIC_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        30 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 2750,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        31 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 3000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [].span(),
        },
        32 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 3250,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        // Legend (Tier 4) - Levels 32+
        33 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 3500,
            free_rewards: [EPIC_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        34 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 3750,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [].span(),
        },
        35 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 4000,
            free_rewards: [EPIC_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        36 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 4250,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        37 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 4500,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        38 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 4750,
            free_rewards: [EPIC_SEASON_4_PACK_ID].span(),
            premium_rewards: [EPIC_SEASON_4_PACK_ID].span(),
        },
        39 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 5000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        40 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 5500,
            free_rewards: [].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        41 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 6000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        42 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 7000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        43 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 8000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        44 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 9000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        45 => SeasonLevelConfig {
            season_id,
            level,
            required_xp: 10000,
            free_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
            premium_rewards: [LEGENDARY_SEASON_4_PACK_ID, LEGENDARY_SEASON_4_PACK_ID].span(),
        },
        _ => SeasonLevelConfig {
            season_id, level, required_xp: 0, free_rewards: [].span(), premium_rewards: [].span(),
        },
    }
}

fn get_season_4_mission_xp(
    season_id: u32, difficulty: u8, completion_count: u32,
) -> MissionXPConfig {
    let xp_reward = match difficulty {
        1 => if completion_count == 0 {
            10
        } else {
            0
        },
        2 => if completion_count == 0 {
            20
        } else {
            0
        },
        3 => if completion_count == 0 {
            30
        } else {
            0
        },
        _ => 0,
    };
    MissionXPConfig { season_id, difficulty, completion_count, xp_reward }
}

fn get_season_4_level_xp(season_id: u32, level: u32, completion_count: u32) -> LevelXPConfig {
    let xp_reward = match level {
        1 => if completion_count == 0 {
            5
        } else {
            0
        },
        2 => if completion_count == 0 {
            10
        } else {
            0
        },
        3 => match completion_count {
            0 => 15,
            1 => 5,
            _ => 0,
        },
        4 => match completion_count {
            0 => 20,
            1 => 10,
            _ => 0,
        },
        5 => match completion_count {
            0 => 25,
            1 => 15,
            2 => 5,
            _ => 0,
        },
        _ => 0,
    };
    LevelXPConfig { season_id, level, completion_count, xp_reward }
}
