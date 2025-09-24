# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dojo-based Cairo smart contract for the Jokers of Neon Profile system. It manages player profiles, statistics, inventory, and seasonal progression in a blockchain game environment built on Starknet.

## Essential Commands

### Building and Development
```bash
# Build the project (also available as: scarb build)
sozo build

# Deploy/migrate contracts
sozo migrate

# Build and migrate in one command
scarb run migrate

# Inspect the world
sozo inspect
```

### Local Development
```bash
# Terminal 1: Start Katana node (required first)
katana --dev --dev.no-fee

# Terminal 2: After Katana is running
sozo build
sozo migrate
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

## Architecture Overview

### Core Components

**Profile System** (`src/systems/profile_system.cairo`):
- Main contract implementing `IJokersProfile` interface
- Uses OpenZeppelin AccessControl with role-based permissions
- Manages player profiles, XP, statistics, and inventory
- Key roles: `DEFAULT_ADMIN_ROLE` and `WRITER_ROLE`

**Data Models** (`src/models.cairo`):
- `Inventory`: Player inventory with slots and quantities
- `InventoryItem`: Individual inventory items by slot
- `SeasonProgress`: Player progress per season with XP and rewards

**External Dependencies**:
- Uses `jokers_of_neon_lib` for shared models (`Profile`, `PlayerStats`)
- Integrates with OpenZeppelin for access control
- Built on Dojo framework v1.6.0-alpha.1

### Data Flow

**Store Pattern** (`src/store.cairo`):
- `StoreTrait` provides typed data access layer
- Wraps Dojo's `WorldStorage` for model read/write operations
- Handles Profile, PlayerStats, Inventory, and SeasonProgress entities

**XP System**:
- Daily XP rewards for missions and level completion
- Diminishing returns for repeated daily activities (max 170 XP/day)
- Seasonal XP accumulation with tier progression
- Free vs Premium distinctions for rewards

### Key Files Structure
- `src/lib.cairo`: Module exports
- `src/systems/profile_system.cairo`: Main contract logic
- `src/models.cairo`: Data model definitions
- `src/store.cairo`: Data access layer
- `src/utils.cairo`: Utility functions
- `src/tests/test_world.cairo`: Test framework setup

## Development Notes

### Configuration Files
- `Scarb.toml`: Package configuration with Dojo v1.6.0-alpha.1
- `dojo_dev.toml`: Development world configuration
- `compose.yaml`: Docker stack for local development

### Access Control
- All write operations require `WRITER_ROLE` permission
- Contract initialization grants admin roles to deployer
- Use `assert_only_role()` for permission checks

### Testing Framework
- Uses `dojo_cairo_test` for contract testing
- Test setup includes world spawning and permission sync
- Tests cover model operations and system interactions

### External Integration
- Depends on `jokers_of_neon_lib` for shared types
- Uses OpenZeppelin v1.0.0 for standard components
- Built for Starknet with Cairo 2.12.2