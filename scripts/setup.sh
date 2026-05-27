#!/bin/bash

set -e

profile="${1:-dev}"

# Validate profile parameter
if [ "$profile" != "dev" ] && [ "$profile" != "slot" ] && [ "$profile" != "testnet" ] && [ "$profile" != "mainnet" ]; then
    echo "Error: Invalid profile. Please use 'dev', 'slot', 'testnet', or 'mainnet'."
    exit 1
fi

echo "Deploying in ${profile}."

# Clean up build artifacts
echo "Cleaning up build artifacts..."
rm -rf "target"
# rm -f "Scarb.lock"

# Remove corresponding manifest file
manifest_file="manifest_${profile}.json"
if [ -f "$manifest_file" ]; then
    echo "Removing manifest file: $manifest_file"
    rm -f "$manifest_file"
fi

echo "sozo build && sozo inspect && sozo migrate"
sozo -P ${profile} build && sozo -P ${profile} inspect && sozo -P ${profile} migrate --use-blake2s-casm-class-hash
echo -e "\n✅ Deployed!"

world_address=$(sozo -P ${profile} inspect | awk '/World/ {getline; getline; print $3}')

# NOTE: setup_default_season_config ya no es necesario.
# Las configs de season ahora estan en constants/season_configs.cairo como funciones puras.

echo -e "\n🎮 Default config xp profile en profile..."
sozo -P ${profile} execute xp_system setup_default_profile_config \
    --wait \
    --world $world_address

echo -e "\n🎮 Create season 3 en profile..."
sozo -P ${profile} execute season_system create_season \
    3 \
    --wait \
    --world $world_address
