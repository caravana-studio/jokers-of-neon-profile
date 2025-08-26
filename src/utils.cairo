use starknet::ContractAddress;
use crate::models::MissionDifficulty;
use crate::store::StoreTrait;
use dojo::world::WorldStorage;

pub fn contains_address(span: @Span<ContractAddress>, address: ContractAddress) -> bool {
    let mut span_copy = *span;
    let mut founded = false;
    loop {
        match span_copy.pop_front() {
            Option::Some(_address) => { if *_address == address {
                founded = true;
                break;
            } },
            Option::None => { break; },
        }
    };
    founded
}

pub fn get_current_day() -> u64 {
    starknet::get_block_timestamp() / 86400 // Seconds per day
}

pub fn get_mission_xp_configurable(world: WorldStorage, season_id: u32, difficulty: MissionDifficulty, completion_count: u32) -> u32 {
    let mut store = StoreTrait::new(world);
    let config = store.get_mission_xp_config(season_id, difficulty, completion_count);
    config.xp_reward
}

pub fn get_level_xp_configurable(world: WorldStorage, season_id: u32, level: u32, completion_count: u32) -> u32 {
    let mut store = StoreTrait::new(world);
    let config = store.get_level_xp_config(season_id, level, completion_count);
    config.xp_reward
}

pub fn get_season_tier_configurable(world: WorldStorage, season_id: u32, season_xp: u256) -> u32 {
    let mut store = StoreTrait::new(world);
    let mut current_tier = 0;
    
    // Find the highest tier that the player qualifies for
    let mut tier = 1;
    loop {
        let tier_config = store.get_season_tier_config(season_id, tier);
        if tier_config.required_xp == 0 {
            break; // No more tiers configured
        }
        if season_xp >= tier_config.required_xp {
            current_tier = tier;
        }
        tier += 1;
        if tier > 50 { // Safety limit
            break;
        }
    };

    current_tier
}
