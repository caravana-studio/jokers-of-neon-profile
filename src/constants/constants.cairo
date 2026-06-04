pub fn DEFAULT_NS() -> felt252 {
    'jokers_of_neon_profile20'
}

pub fn DEFAULT_NS_BYTE() -> ByteArray {
    "jokers_of_neon_profile20"
}

pub fn MOD_ID() -> felt252 {
    'jokers_of_neon_classic'
}

pub const NFT_MANAGER_KEY: felt252 = selector!("NFT_MANAGER_KEY");
pub const PERMISSION_CONFIG_KEY: felt252 = selector!("PERMISSION_CONFIG_KEY");
pub const TOURNAMENT_TICKET_REWARD_ID: u32 = 99;
pub const STREAK_PROTECTOR_REWARD_ID: u32 = 100;
pub const CURRENT_SEASON_ID: u32 = 3;
pub const MISSION_PERIOD_DAILY: u8 = 1;
pub const MISSION_PERIOD_WEEKLY: u8 = 2;
pub const MAX_STREAK_PROTECTORS: u16 = 2;
