use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect, DojoStore)]
pub struct ProgressSnapshot {
    pub tier: u8,
    pub total_runs: u32,
    pub max_level: u32,
    pub max_round: u32,
    pub total_xp: u64,
    pub season_xp: u64,
    pub current_streak: u32,
    pub longest_streak: u32,
    pub protectors: u32,
    pub season_pass: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DurableProgress {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub season_id: u32,
    pub version: u64,
    pub snapshot: ProgressSnapshot,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DurableResult {
    #[key]
    pub game_id: u64,
    pub player: ContractAddress,
    pub level: u32,
    pub round: u32,
    pub score: u64,
    pub finished_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DurableOperationReceipt {
    #[key]
    pub operation_id: u128,
    pub payload_hash: felt252,
    pub applied: bool,
}

#[starknet::interface]
pub trait IDurableSettlement<T> {
    fn publish_progress(ref self: T, operation_id: u128, progress: DurableProgress);
    fn publish_result(ref self: T, operation_id: u128, result: DurableResult);
    fn get_progress(self: @T, player: ContractAddress, season_id: u32) -> DurableProgress;
    fn get_result(self: @T, game_id: u64) -> DurableResult;
}

/// Additive, versioned writer. It must replace legacy XP writers at a reconciled cutover.
#[dojo::contract]
pub mod durable_settlement_system {
    use core::num::traits::Zero;
    use core::poseidon::poseidon_hash_span;
    use dojo::model::ModelStorage;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::constants::constants::DEFAULT_NS_BYTE;
    use crate::store::{Store, StoreTrait};
    use crate::systems::permission_system::{IPermissionsDispatcher, IPermissionsDispatcherTrait};
    use super::{DurableOperationReceipt, DurableProgress, DurableResult};

    #[abi(embed_v0)]
    impl SettlementImpl of super::IDurableSettlement<ContractState> {
        fn publish_progress(
            ref self: ContractState, operation_id: u128, progress: DurableProgress,
        ) {
            let mut store = self.authorized_store();
            assert!(
                progress.player.is_non_zero()
                    && progress.season_id != 0
                    && progress.version != 0
                    && progress.snapshot.tier <= 22,
                "Invalid progress",
            );
            let mut serialized = array!['progress'];
            Serde::serialize(@progress, ref serialized);
            if !self
                .record_operation(ref store, operation_id, poseidon_hash_span(serialized.span())) {
                return;
            }
            let previous: DurableProgress = store
                .world
                .read_model((progress.player, progress.season_id));
            assert!(progress.version > previous.version, "Stale progress version");
            store.world.write_model(@progress);
        }

        fn publish_result(ref self: ContractState, operation_id: u128, result: DurableResult) {
            let mut store = self.authorized_store();
            assert!(
                result.game_id > 0
                    && result.game_id <= 9223372036854775807
                    && result.player.is_non_zero()
                    && result.finished_at != 0,
                "Invalid game result",
            );
            let mut serialized = array!['result'];
            Serde::serialize(@result, ref serialized);
            let hash = poseidon_hash_span(serialized.span());
            if !self.record_operation(ref store, operation_id, hash) {
                return;
            }
            let previous: DurableResult = store.world.read_model(result.game_id);
            if previous.player.is_non_zero() {
                let mut previous_data = array!['result'];
                Serde::serialize(@previous, ref previous_data);
                assert!(poseidon_hash_span(previous_data.span()) == hash, "Game result conflict");
            }
            store.world.write_model(@result);
        }

        fn get_progress(
            self: @ContractState, player: ContractAddress, season_id: u32,
        ) -> DurableProgress {
            self.world(@DEFAULT_NS_BYTE()).read_model((player, season_id))
        }
        fn get_result(self: @ContractState, game_id: u64) -> DurableResult {
            self.world(@DEFAULT_NS_BYTE()).read_model(game_id)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn authorized_store(self: @ContractState) -> Store {
            let mut store = StoreTrait::new(self.world(@DEFAULT_NS_BYTE()));
            let permission = store.get_permission_config();
            let caller = get_caller_address();
            // Unlike the legacy permission helper, an uninitialized configuration denies writes.
            assert!(permission.owner.is_non_zero(), "Settlement not configured");
            if caller != permission.owner {
                assert!(permission.permissions_address.is_non_zero(), "Unauthorized settlement");
                let dispatcher = IPermissionsDispatcher {
                    contract_address: permission.permissions_address,
                };
                assert!(
                    dispatcher.has_permission(get_contract_address(), caller),
                    "Unauthorized settlement",
                );
            }
            store
        }
        fn record_operation(
            self: @ContractState, ref store: Store, operation_id: u128, hash: felt252,
        ) -> bool {
            assert!(operation_id != 0, "Invalid operation id");
            let previous: DurableOperationReceipt = store.world.read_model(operation_id);
            if previous.applied {
                assert!(previous.payload_hash == hash, "Operation conflict");
                return false;
            }
            store
                .world
                .write_model(
                    @DurableOperationReceipt { operation_id, payload_hash: hash, applied: true },
                );
            true
        }
    }
}
