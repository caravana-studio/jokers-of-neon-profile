use starknet::ContractAddress;

#[starknet::interface]
pub trait IPermissionSystem<T> {
    fn initialize(ref self: T, permissions_address: ContractAddress);
    fn assert_has_permission(self: @T, contract_address: ContractAddress, caller: ContractAddress);
}

// This is the interface for the permissions contract
#[starknet::interface]
pub trait IPermissions<T> {
    fn has_permission(
        self: @T, contract_address: ContractAddress, caller_address: ContractAddress,
    ) -> bool;
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PermissionConfig {
    #[key]
    pub key: felt252,
    pub owner: ContractAddress,
    pub permissions_address: ContractAddress,
}

#[dojo::contract]
pub mod permission_system {
    use core::num::traits::Zero;
    use openzeppelin_access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin_introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use crate::constants::constants::{DEFAULT_NS_BYTE, PERMISSION_CONFIG_KEY};
    use crate::store::{Store, StoreTrait};
    use super::{
        IPermissionSystem, IPermissionsDispatcher, IPermissionsDispatcherTrait, PermissionConfig,
    };

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn create_store(self: @ContractState) -> Store {
            let mut world = self.world(@DEFAULT_NS_BYTE());
            StoreTrait::new(world)
        }
    }

    fn dojo_init(ref self: ContractState, creator_address: ContractAddress) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, creator_address);
    }

    #[abi(embed_v0)]
    impl PermissionSystem of IPermissionSystem<ContractState> {
        fn initialize(ref self: ContractState, permissions_address: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);

            let mut store = self.create_store();
            store
                .set_permission_config(
                    PermissionConfig {
                        key: PERMISSION_CONFIG_KEY,
                        owner: starknet::get_caller_address(),
                        permissions_address,
                    },
                );
        }

        fn assert_has_permission(
            self: @ContractState, contract_address: ContractAddress, caller: ContractAddress,
        ) {
            let mut store = self.create_store();
            let contract_address = store.get_permission_config().permissions_address;

            if contract_address.is_non_zero() {
                let dispatcher = IPermissionsDispatcher { contract_address };
                assert!(
                    dispatcher.has_permission(contract_address, caller),
                    "[Permission System] - Caller `{:x}` does not have permission for contract `{:x}`.",
                    caller,
                    contract_address,
                );
            }
        }
    }
}
