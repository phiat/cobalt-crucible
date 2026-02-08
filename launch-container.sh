#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <container-name>"
    echo "Example: $0 my-new-dev"
    echo ""
    echo "Requires TAILSCALE_AUTHKEY environment variable or ~/.tailscale-authkey file"
    exit 1
fi

CONTAINER_NAME=$1

# Get Tailscale auth key from env var or file
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    AUTHKEY="$TAILSCALE_AUTHKEY"
elif [ -f "$HOME/.tailscale-authkey" ]; then
    AUTHKEY=$(cat "$HOME/.tailscale-authkey")
else
    echo "❌ Error: No Tailscale auth key found"
    echo "   Set TAILSCALE_AUTHKEY env var or create ~/.tailscale-authkey file"
    exit 1
fi

echo "🚀 Launching container: $CONTAINER_NAME"
incus launch cobalt-crucible-base "$CONTAINER_NAME"

echo "⏳ Waiting for container to be ready..."
sleep 3

echo "🔗 Connecting to Tailscale..."
incus exec "$CONTAINER_NAME" -- tailscale up --authkey="$AUTHKEY" --hostname="$CONTAINER_NAME"

echo "✅ Container ready!"
echo ""
echo "Tailscale IP:"
incus exec "$CONTAINER_NAME" -- tailscale ip -4

echo ""
echo "Access with:"
echo "  incus shell $CONTAINER_NAME"
echo "  ssh root@\$(incus exec $CONTAINER_NAME -- tailscale ip -4)"
