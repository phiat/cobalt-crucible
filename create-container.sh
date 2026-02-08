#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <container-name>"
    echo "Example: $0 my-dev"
    exit 1
fi

CONTAINER_NAME=$1
SNAPSHOT_ALIAS="cobalt-crucible-base"

echo "🚀 Creating container: $CONTAINER_NAME"

# Check if snapshot exists
if incus image list | grep -q "$SNAPSHOT_ALIAS"; then
    echo "✓ Using snapshot: $SNAPSHOT_ALIAS"
    incus launch "$SNAPSHOT_ALIAS" "$CONTAINER_NAME"

    echo "⏳ Waiting for container to be ready..."
    sleep 3
else
    echo "⚠ No snapshot found - building from scratch (this will take a while)..."
    bash setup.sh "$CONTAINER_NAME" ./provision.sh

    echo ""
    echo "💡 Tip: Create a snapshot for faster future launches:"
    echo "   incus stop $CONTAINER_NAME"
    echo "   incus publish $CONTAINER_NAME --alias $SNAPSHOT_ALIAS"
    echo "   incus start $CONTAINER_NAME"
    echo ""
fi


# Setup Tailscale if auth key is available
if [ -n "$TAILSCALE_AUTHKEY" ] || [ -f "$HOME/.tailscale-authkey" ]; then
    AUTHKEY="${TAILSCALE_AUTHKEY:-$(cat "$HOME/.tailscale-authkey" 2>/dev/null)}"

    if [ -n "$AUTHKEY" ]; then
        echo "🔗 Connecting to Tailscale with SSH enabled..."
        incus exec "$CONTAINER_NAME" -- tailscale up --authkey="$AUTHKEY" --hostname="$CONTAINER_NAME" --ssh > /dev/null 2>&1

        TAILSCALE_IP=$(incus exec "$CONTAINER_NAME" -- tailscale ip -4 2>/dev/null)

        if [ -n "$TAILSCALE_IP" ]; then
            echo "✅ Container ready with Tailscale!"
            echo ""
            echo "Tailscale IP: $TAILSCALE_IP"
            echo ""
            echo "Access with:"
            echo "  ssh root@$TAILSCALE_IP"
            echo "  incus shell $CONTAINER_NAME"
        else
            echo "⚠ Tailscale connection failed"
            echo "✅ Container ready (without Tailscale)"
            echo ""
            echo "Access with:"
            echo "  incus shell $CONTAINER_NAME"
        fi
    fi
else
    echo "✅ Container ready!"
    echo ""
    echo "Access with:"
    echo "  incus shell $CONTAINER_NAME"
    echo ""
    echo "💡 Tip: Set TAILSCALE_AUTHKEY to auto-connect to Tailscale"
fi
