#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <container-name> <setup-script-path>"
    echo "Example: $0 my-dev-container ~/dev-setup.sh"
    exit 1
fi

CONTAINER_NAME=$1
SCRIPT_PATH=$2

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: Setup script not found at $SCRIPT_PATH"
    exit 1
fi

echo "🚀 Creating container: $CONTAINER_NAME"
incus launch images:ubuntu/24.04 "$CONTAINER_NAME"

echo "⏳ Waiting for container to be ready..."
sleep 3

echo "🔒 Applying resource limits..."
incus config set "$CONTAINER_NAME" limits.memory 4GB
incus config set "$CONTAINER_NAME" limits.cpu 2

echo -e "\n🐎 Running setup script...\n"
cat "$SCRIPT_PATH" | incus exec "$CONTAINER_NAME" -- bash

echo -e "\n✅ Setup complete! Access with: incus shell $CONTAINER_NAME"
