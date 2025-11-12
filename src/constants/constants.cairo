pub fn DEFAULT_NS() -> felt252 {
    'jokers_of_neon_profile7'
}

pub fn DEFAULT_NS_BYTE() -> ByteArray {
    "jokers_of_neon_profile7"
}

pub fn MOD_ID() -> felt252 {
    'jokers_of_neon_classic'
}

pub const PERCENT_SCALE: u32 = 10000;

pub const TWELVE_HOURS: u64 = 12 * 60 * 60;
pub const SIX_HOURS: u64 = 6 * 60 * 60;

pub const FREE_PACK_COOLDOWN: u64 = 43200; // 12 hours
pub const FREE_PACK_CONFIG_KEY: felt252 = selector!("FREE_PACK_CONFIG_KEY");

pub const NFT_MANAGER_KEY: felt252 = selector!("NFT_MANAGER_KEY");

pub const LIVES_CONFIG_KEY: felt252 = selector!("LIVES_CONFIG_KEY");

pub const TOURNAMENT_TICKET_REWARD_ID: u32 = 99;
