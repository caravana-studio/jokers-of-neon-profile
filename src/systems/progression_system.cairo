use starknet::ContractAddress;

#[starknet::interface]
pub trait IProgressionSystem<T> {
    fn sync_progression(
        ref self: T,
        player: ContractAddress,
        tier: u8,
        total_runs: u32,
        max_level: u32,
        max_round: u32,
    );
    fn get_progression(self: @T, player: ContractAddress) -> (u8, u32, u32, u32);
}

#[dojo::contract]
pub mod progression_system {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::constants::constants::DEFAULT_NS_BYTE;
    use crate::models::PlayerProgression;
    use crate::store::{Store, StoreTrait};
    use crate::systems::permission_system::IPermissionSystemDispatcherTrait;
    use crate::utils::systems::SystemsTrait;

    #[abi(embed_v0)]
    impl ProgressionSystemImpl of super::IProgressionSystem<ContractState> {
        fn sync_progression(
            ref self: ContractState,
            player: ContractAddress,
            tier: u8,
            total_runs: u32,
            max_level: u32,
            max_round: u32,
        ) {
            let mut store = self.create_store();
            SystemsTrait::permission(store.world)
                .assert_has_permission(get_contract_address(), get_caller_address());

            let existing = store.get_player_progression(player);

            // Use max values to avoid overwriting better progression
            let new_tier = if tier > existing.tier { tier } else { existing.tier };
            let new_total_runs = if total_runs > existing.total_runs {
                total_runs
            } else {
                existing.total_runs
            };
            let new_max_level = if max_level > existing.max_level {
                max_level
            } else {
                existing.max_level
            };
            let new_max_round = if max_level > existing.max_level {
                max_round
            } else if max_level == existing.max_level && max_round > existing.max_round {
                max_round
            } else {
                existing.max_round
            };

            store
                .set_player_progression(
                    PlayerProgression {
                        address: player,
                        tier: new_tier,
                        total_runs: new_total_runs,
                        max_level: new_max_level,
                        max_round: new_max_round,
                    },
                );
        }

        fn get_progression(self: @ContractState, player: ContractAddress) -> (u8, u32, u32, u32) {
            let mut store = self.create_store();
            let progression = store.get_player_progression(player);
            (progression.tier, progression.total_runs, progression.max_level, progression.max_round)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn create_store(self: @ContractState) -> Store {
            let world = self.world(@DEFAULT_NS_BYTE());
            StoreTrait::new(world)
        }
    }
}
