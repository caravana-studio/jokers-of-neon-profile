use crate::models::{
    Owners, InventoryItem, Inventory, SeasonProgress, DailyProgress, MissionXPConfig, 
    LevelXPConfig, SeasonConfig, SeasonTierConfig, MissionDifficulty
};
use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile};
use dojo::{model::ModelStorage, world::WorldStorage};
use starknet::ContractAddress;

#[derive(Drop)]
struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline(always)]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    fn get_profile(ref self: Store, address: ContractAddress) -> Profile {
        self.world.read_model(address)
    }

    fn set_profile(ref self: Store, profile: Profile) {
        self.world.write_model(@profile)
    }

    fn get_player_stats(ref self: Store, address: ContractAddress) -> PlayerStats {
        self.world.read_model(address)
    }

    fn set_player_stats(ref self: Store, player_stats: PlayerStats) {
        self.world.write_model(@player_stats)
    }

    fn get_inventory_item(ref self: Store, address: ContractAddress, slot: u32) -> InventoryItem {
        self.world.read_model((address, slot))
    }

    fn set_inventory_item(ref self: Store, inventory_item: InventoryItem) {
        self.world.write_model(@inventory_item)
    }

    fn get_inventory(ref self: Store, address: ContractAddress) -> Inventory {
        self.world.read_model(address)
    }

    fn set_inventory(ref self: Store, inventory: Inventory) {
        self.world.write_model(@inventory)
    }

    fn get_season_progress(
        ref self: Store, address: ContractAddress, season_id: u32,
    ) -> SeasonProgress {
        self.world.read_model((address, season_id))
    }

    fn set_season_progress(ref self: Store, season_progress: SeasonProgress) {
        self.world.write_model(@season_progress)
    }

    fn get_owners(ref self: Store) -> Owners {
        self.world.read_model('OWNERS_KEY')
    }

    fn set_owners(ref self: Store, owners: Span<ContractAddress>) {
        self.world.write_model(@Owners { key: 'OwNERS_KEY', owners })
    }

    fn get_daily_progress(ref self: Store, address: ContractAddress, day: u64) -> DailyProgress {
        self.world.read_model((address, day))
    }

    fn set_daily_progress(ref self: Store, daily_progress: DailyProgress) {
        self.world.write_model(@daily_progress)
    }

    fn get_mission_xp_config(ref self: Store, season_id: u32, difficulty: MissionDifficulty, completion_count: u32) -> MissionXPConfig {
        self.world.read_model((season_id, difficulty, completion_count))
    }

    fn set_mission_xp_config(ref self: Store, config: MissionXPConfig) {
        self.world.write_model(@config)
    }

    fn get_level_xp_config(ref self: Store, season_id: u32, level: u32, completion_count: u32) -> LevelXPConfig {
        self.world.read_model((season_id, level, completion_count))
    }

    fn set_level_xp_config(ref self: Store, config: LevelXPConfig) {
        self.world.write_model(@config)
    }

    fn get_season_config(ref self: Store, season_id: u32) -> SeasonConfig {
        self.world.read_model(season_id)
    }

    fn set_season_config(ref self: Store, config: SeasonConfig) {
        self.world.write_model(@config)
    }

    fn get_season_tier_config(ref self: Store, season_id: u32, tier: u32) -> SeasonTierConfig {
        self.world.read_model((season_id, tier))
    }

    fn set_season_tier_config(ref self: Store, config: SeasonTierConfig) {
        self.world.write_model(@config)
    }
}
