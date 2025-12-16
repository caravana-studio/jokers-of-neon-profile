pub mod systems {
    pub mod permission_system;
    pub mod profile_system;
    pub mod season_system;
    pub mod xp_system;
}

pub mod constants {
    pub mod constants;
    pub mod packs;
}

pub mod models;
pub mod store;

pub mod utils {
    pub mod systems;
    pub mod utils;
}

#[cfg(test)]
pub mod tests {}
