#!/bin/bash

set -e

profile="${1:-dev}"
profile_system_address="${2:-}"

# Validate profile parameter
if [ "$profile" != "dev" ] && [ "$profile" != "slot" ] && [ "$profile" != "testnet" ] && [ "$profile" != "mainnet" ]; then
    echo "Error: Invalid profile. Please use 'dev', 'slot', 'testnet', or 'mainnet'."
    exit 1
fi

echo "Deploying in ${profile}."

# Clean up build artifacts
echo "Cleaning up build artifacts..."
rm -rf "target"
rm -f "Scarb.lock"

# Remove corresponding manifest file
manifest_file="manifest_${profile}.json"
if [ -f "$manifest_file" ]; then
    echo "Removing manifest file: $manifest_file"
    rm -f "$manifest_file"
fi

echo "sozo build && sozo inspect && sozo migrate"
sozo -P ${profile} build && sozo -P ${profile} inspect && sozo -P ${profile} migrate

echo -e "\n✅ Deployed!"

world_address=$(sozo -P ${profile} inspect | awk '/World/ {getline; getline; print $3}')

echo -e "\n🎮 Default config season en profile..."
sozo -P ${profile} execute xp_system setup_default_season_config \
    1 \
    --wait \
    --world $world_address

echo -e "\n🎮 Default config xp profile en profile..."
sozo -P ${profile} execute xp_system setup_default_profile_config \
    --wait \
    --world $world_address

echo -e "\n🎮 Register game system in profile..."
sozo -P ${profile} execute profile_system grant_role \
    0x038f168f361ac1393a163ed4adfa899a87be7b7c71645167bdaddd822ae453c8 \
    $profile_system_address \
    --wait \
    --world $world_address
