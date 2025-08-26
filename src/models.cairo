use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Inventory {
    #[key]
    pub address: ContractAddress,
    pub items_quantity: u32,
    pub available_slots: u32,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct InventoryItem {
    #[key]
    pub address: ContractAddress,
    #[key]
    pub slot: u32,
    pub item_id: u32,
    pub quantity: u32,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct SeasonProgress {
    #[key]
    pub address: ContractAddress,
    #[key]
    pub season_id: u32,
    pub season_xp: u256,
    pub has_season_pass: bool,
    pub claimable_rewards_id: Span<u32>,
    pub tier: u32,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum MissionDifficulty {
    Easy,
    Medium,
    Hard,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct DailyProgress {
    #[key]
    pub address: ContractAddress,
    #[key]
    pub day: u64,
    pub daily_xp: u32,
    pub easy_missions: u32,
    pub medium_missions: u32,
    pub hard_missions: u32,
    pub level1_completions: u32,
    pub level2_completions: u32,
    pub level3_completions: u32,
    pub level4_completions: u32,
    pub level5_completions: u32,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Owners {
    #[key]
    pub key: felt252,
    pub owners: Span<ContractAddress>,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct MissionXPConfig {
    #[key]
    pub season_id: u32,
    #[key]
    pub difficulty: MissionDifficulty,
    #[key]
    pub completion_count: u32,
    pub xp_reward: u32,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct LevelXPConfig {
    #[key]
    pub season_id: u32,
    #[key]
    pub level: u32,
    #[key]
    pub completion_count: u32,
    pub xp_reward: u32,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct SeasonConfig {
    #[key]
    pub season_id: u32,
    pub is_active: bool,
}

#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct SeasonTierConfig {
    #[key]
    pub season_id: u32,
    #[key]
    pub tier: u32,
    pub required_xp: u256,
    pub tier_name: ByteArray,
    pub free_rewards: Span<u32>,
    pub premium_rewards: Span<u32>,
}
