use crate::models::MissionDifficulty;
use crate::store::StoreTrait;
use dojo::world::WorldStorage;

pub fn get_current_day() -> u64 {
    starknet::get_block_timestamp() / 86400 // Seconds per day
}

pub fn get_mission_xp_configurable(
    world: WorldStorage, season_id: u32, difficulty: MissionDifficulty, completion_count: u32,
) -> u32 {
    let mut store = StoreTrait::new(world);
    let config = store.get_mission_xp_config(season_id, difficulty, completion_count);
    config.xp_reward
}

pub fn get_level_xp_configurable(
    world: WorldStorage, season_id: u32, level: u32, completion_count: u32,
) -> u32 {
    let mut store = StoreTrait::new(world);
    let config = store.get_level_xp_config(season_id, level, completion_count);
    config.xp_reward
}

pub fn get_season_nivel(world: WorldStorage, season_id: u32, season_xp: u256) -> u32 {
    let mut store = StoreTrait::new(world);
    let mut current_nivel = 0;

    // Find the highest nivel that the player qualifies for
    let mut nivel = 1;
    loop {
        let nivel_config = store.get_season_nivel_config(season_id, nivel);
        if nivel_config.required_xp == 0 {
            break; // No more niveles configured
        }
        if season_xp >= nivel_config.required_xp {
            current_nivel = nivel;
        }
        nivel += 1;
        if nivel > 50 { // Safety limit
            break;
        }
    };

    current_nivel
}

pub fn get_tier_from_nivel(nivel: u32) -> u32 {
    if nivel >= 1 && nivel <= 11 {
        1 // Casual
    } else if nivel >= 12 && nivel <= 25 {
        2 // Average
    } else if nivel >= 26 && nivel <= 32 {
        3 // Hardcore
    } else { // if nivel >= 33
        4 // Legend
    }
}
