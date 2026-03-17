#!/bin/bash
# Clears account_address and private_key in dojo_mainnet.toml back to empty strings

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TOML_FILE="$PROJECT_DIR/dojo_mainnet.toml"

sed -i '' 's|^account_address = ".*"|account_address = ""|' "$TOML_FILE"
sed -i '' 's|^private_key = ".*"|private_key = ""|' "$TOML_FILE"

echo "dojo_mainnet.toml cleaned: account_address and private_key set to empty"
