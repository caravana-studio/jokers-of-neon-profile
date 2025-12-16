use dojo::world::{WorldStorage, WorldStorageTrait};
use crate::systems::permission_system::IPermissionSystemDispatcher;

fn PERMISSION_SYSTEM() -> ByteArray {
    "permission_system"
}

#[generate_trait]
pub impl Systems of SystemsTrait {
    fn permission(world: WorldStorage) -> IPermissionSystemDispatcher {
        match world.dns(@PERMISSION_SYSTEM()) {
            Option::Some((
                contract_address, _,
            )) => { IPermissionSystemDispatcher { contract_address } },
            Option::None => {
                panic!(
                    "[SystemsTrait] - dns `{}` doesnt exists on world `{}`",
                    PERMISSION_SYSTEM(),
                    world.namespace_hash,
                )
            },
        }
    }
}
