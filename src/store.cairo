use dojo::model::ModelStorage;
use dojo::world::WorldStorage;
use jokers_of_neon_lib::models::external::profile::{PlayerStats, Profile, ProfileLevelConfig};
use starknet::ContractAddress;
use crate::models::{
    ClaimedReward, DailyProgress, LevelXPConfig, MissionDifficulty, MissionXPConfig, Season,
    SeasonLevelConfig, SeasonProgress, SeasonReward,
};

#[derive(Drop)]
pub struct Store {
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

    fn get_season_reward(ref self: Store, reward_id: u32) -> SeasonReward {
        self.world.read_model(reward_id)
    }

    fn set_season_reward(ref self: Store, reward: SeasonReward) {
        self.world.write_model(@reward)
    }

    fn get_claimed_reward(
        ref self: Store, address: ContractAddress, season_id: u32, level: u32, is_premium: bool,
    ) -> ClaimedReward {
        self.world.read_model((address, season_id, level, is_premium))
    }

    fn set_claimed_reward(ref self: Store, claimed_reward: ClaimedReward) {
        self.world.write_model(@claimed_reward)
    }
}
