#!/bin/bash
# Reads ACCOUNT_ADDRESS and PRIVATE_KEY from .env and fills them into dojo_mainnet.toml

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"
TOML_FILE="$PROJECT_DIR/dojo_mainnet.toml"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

if [ -z "$ACCOUNT_ADDRESS" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "Error: ACCOUNT_ADDRESS or PRIVATE_KEY not found in .env"
    exit 1
fi

sed -i '' "s|^account_address = \".*\"|account_address = \"$ACCOUNT_ADDRESS\"|" "$TOML_FILE"
sed -i '' "s|^private_key = \".*\"|private_key = \"$PRIVATE_KEY\"|" "$TOML_FILE"

echo "dojo_mainnet.toml updated with account_address and private_key from .env"
