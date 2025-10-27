use dojo::model::ModelStorage;
use dojo::world::WorldStorage;
use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
use starknet::ContractAddress;
use crate::constants::constants::{FREE_PACK_CONFIG_KEY, LIVES_CONFIG_KEY, NFT_MANAGER_KEY};
use crate::models::{
    DailyProgress, FreePackConfig, Item, LevelXPConfig, LivesConfig, MissionDifficulty,
    MissionXPConfig, NFTManager, Pack, PlayerFreePack, PlayerLives, Season, SeasonContent,
    SeasonLevelConfig, SeasonProgress,
};

#[derive(Drop)]
pub struct Store {
    pub world: WorldStorage,
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

    fn get_season_progress(
        ref self: Store, address: ContractAddress, season_id: u32,
    ) -> SeasonProgress {
        self.world.read_model((address, season_id))
    }

    fn set_season_progress(ref self: Store, season_progress: SeasonProgress) {
        self.world.write_model(@season_progress)
    }

    fn get_daily_progress(ref self: Store, address: ContractAddress, day: u64) -> DailyProgress {
        self.world.read_model((address, day))
    }

    fn set_daily_progress(ref self: Store, daily_progress: DailyProgress) {
        self.world.write_model(@daily_progress)
    }

    fn get_mission_xp_config(
        ref self: Store, season_id: u32, difficulty: MissionDifficulty, completion_count: u32,
    ) -> MissionXPConfig {
        self.world.read_model((season_id, difficulty, completion_count))
    }

    fn set_mission_xp_config(ref self: Store, config: MissionXPConfig) {
        self.world.write_model(@config)
    }

    fn get_level_xp_config(
        ref self: Store, season_id: u32, level: u32, completion_count: u32,
    ) -> LevelXPConfig {
        self.world.read_model((season_id, level, completion_count))
    }

    fn set_level_xp_config(ref self: Store, config: LevelXPConfig) {
        self.world.write_model(@config)
    }

    fn get_season_level_config(ref self: Store, season_id: u32, level: u32) -> SeasonLevelConfig {
        self.world.read_model((season_id, level))
    }

    fn set_season_level_config(ref self: Store, config: SeasonLevelConfig) {
        self.world.write_model(@config)
    }

    fn get_profile_level_config(ref self: Store, level: u32) -> ProfileLevelConfig {
        self.world.read_model(level)
    }

    fn set_profile_level_config(ref self: Store, config: ProfileLevelConfig) {
        self.world.write_model(@config)
    }

    fn get_season(ref self: Store, season_id: u32) -> Season {
        self.world.read_model(season_id)
    }

    fn set_season(ref self: Store, season: Season) {
        self.world.write_model(@season)
    }

    fn get_lives_config(ref self: Store) -> LivesConfig {
        self.world.read_model(LIVES_CONFIG_KEY)
    }

    fn set_lives_config(ref self: Store, config: LivesConfig) {
        self.world.write_model(@config)
    }

    fn get_player_lives(ref self: Store, address: ContractAddress, season_id: u32) -> PlayerLives {
        self.world.read_model((address, season_id))
    }

    fn set_player_lives(ref self: Store, lives: PlayerLives) {
        self.world.write_model(@lives)
    }

    fn get_pack(ref self: Store, id: u32) -> Pack {
        self.world.read_model(id)
    }

    fn set_pack(ref self: Store, pack: Pack) {
        self.world.write_model(@pack)
    }

    fn get_season_content(ref self: Store, season_id: u32) -> SeasonContent {
        self.world.read_model(season_id)
    }

    fn set_season_content(ref self: Store, season_content: SeasonContent) {
        self.world.write_model(@season_content)
    }

    fn get_item(ref self: Store, id: u32) -> Item {
        self.world.read_model(id)
    }

    fn set_item(ref self: Store, item: Item) {
        self.world.write_model(@item)
    }

    fn get_nft_manager(ref self: Store) -> NFTManager {
        self.world.read_model(NFT_MANAGER_KEY)
    }

    fn set_nft_manager(ref self: Store, nft_manager: NFTManager) {
        self.world.write_model(@nft_manager)
    }

    fn get_free_pack_config(ref self: Store) -> FreePackConfig {
        self.world.read_model(FREE_PACK_CONFIG_KEY)
    }

    fn set_free_pack_config(ref self: Store, config: FreePackConfig) {
        self.world.write_model(@config)
    }

    fn get_player_free_pack(ref self: Store, address: ContractAddress) -> PlayerFreePack {
        self.world.read_model(address)
    }

    fn set_player_free_pack(ref self: Store, player_free_pack: PlayerFreePack) {
        self.world.write_model(@player_free_pack)
    }
}
