use dojo::model::ModelStorage;
use dojo::world::WorldStorage;
use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
use starknet::ContractAddress;
use crate::constants::constants::NFT_MANAGER_KEY;
use crate::models::{
    DailyProgress, GameData, LevelXPConfig, MissionXPConfig, NFTManager, PokerHandData, RoundData,
    SeasonConfig, SeasonLevelConfig, SeasonProgress, SeasonRewardClaim,
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

    fn set_profile(ref self: Store, profile: @Profile) {
        self.world.write_model(profile)
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

    fn set_season_progress(ref self: Store, season_progress: @SeasonProgress) {
        self.world.write_model(season_progress)
    }

    fn get_daily_progress(ref self: Store, address: ContractAddress, day: u64) -> DailyProgress {
        self.world.read_model((address, day))
    }

    fn set_daily_progress(ref self: Store, daily_progress: DailyProgress) {
        self.world.write_model(@daily_progress)
    }

    fn get_mission_xp_config(
        ref self: Store, season_id: u32, difficulty: u8, completion_count: u32,
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

    fn get_season_config(ref self: Store, season_id: u32) -> SeasonConfig {
        self.world.read_model(season_id)
    }

    fn set_season_config(ref self: Store, config: SeasonConfig) {
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

    fn get_nft_manager(ref self: Store) -> NFTManager {
        self.world.read_model(NFT_MANAGER_KEY)
    }

    fn set_nft_manager(ref self: Store, nft_manager: NFTManager) {
        self.world.write_model(@nft_manager)
    }

    fn get_season_reward_claim(
        ref self: Store, player: ContractAddress, season_id: u32, level: u32,
    ) -> SeasonRewardClaim {
        self.world.read_model((player, season_id, level))
    }

    fn set_season_reward_claim(ref self: Store, claim: SeasonRewardClaim) {
        self.world.write_model(@claim)
    }

    fn get_game_data(ref self: Store, address: ContractAddress) -> GameData {
        self.world.read_model(address)
    }

    fn set_game_data(ref self: Store, game_data: GameData) {
        self.world.write_model(@game_data)
    }

    fn get_round_data(ref self: Store, address: ContractAddress) -> RoundData {
        self.world.read_model(address)
    }

    fn set_round_data(ref self: Store, round_data: RoundData) {
        self.world.write_model(@round_data)
    }

    fn get_poker_hand_data(ref self: Store, address: ContractAddress) -> PokerHandData {
        self.world.read_model(address)
    }

    fn set_poker_hand_data(ref self: Store, poker_hand_data: PokerHandData) {
        self.world.write_model(@poker_hand_data)
    }
}
