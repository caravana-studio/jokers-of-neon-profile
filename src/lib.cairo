pub mod systems {
    pub mod lives_system;
    pub mod pack_system;
    pub mod profile_system;
    pub mod xp_system;
}

pub mod constants {
    pub mod constants;
    pub mod items;
    pub mod packs;
}

pub mod models;
pub mod store;

pub mod utils {
    pub mod pack;
    pub mod utils;
}

#[cfg(test)]
pub mod tests {
    pub mod test_pack_trait;
}
