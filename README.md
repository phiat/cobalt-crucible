# cobalt-crucible

Incus dev container setup for WSL2.

## Quick Start

**From snapshot (fast — seconds):**

```bash
incus launch cobalt-crucible-base <name>
```

**From scratch (full build — 15-20 min):**

```bash
./create-dev-container.sh <name> ./dev-setup.sh
```

Then shell in:

```bash
incus shell <name>
```

## What Gets Installed

`dev-setup.sh` provisions the container with:

- **System**: build-essential, curl, wget, git, htop, tmux, net-tools, etc.
- **Shell**: zsh + Oh My Zsh (robbyrussell theme)
- **Languages** (via mise): Node.js, Go, Rust, Erlang, Elixir, Python, Java, Clojure, Zig, Bun
- **CLI tools** (via mise): jq, bat, typst, lazydocker
- **Containers**: Podman
- **Networking**: Tailscale
- **Dev tools**: Claude Code, OpenCode, fzf

## Snapshots

Build once, launch instantly. After a full build:

```bash
# Stop the container
incus stop <name>

# Publish as a reusable image
incus publish <name> --alias cobalt-crucible-base

# Restart the original
incus start <name>
```

Launch new containers from the snapshot:

```bash
incus launch cobalt-crucible-base my-new-container
```

Update the snapshot after changes:

```bash
incus stop <name>
incus image delete cobalt-crucible-base
incus publish <name> --alias cobalt-crucible-base
incus start <name>
```

List local images:

```bash
incus image list
```

## Resource Limits

Set in `create-dev-container.sh` after launch (applied live, no restart needed):

| Resource | Limit | Config key |
|----------|-------|------------|
| Memory | 8GB (hard cap) | `limits.memory` |
| CPU | 8 cores | `limits.cpu` |

Adjust per container:

```bash
incus config set <name> limits.memory 4GB
incus config set <name> limits.cpu 2
incus config set <name> limits.cpu.allowance 50%
incus config device set <name> root size=20GB
```

## Auth

Claude Code uses OAuth and tokens aren't portable across machines. After launching a new container, log in manually:

```bash
incus shell <name>
claude login
```

## lxcfs on WSL2

By default, `/proc/meminfo` inside the container reports host memory even with limits set. lxcfs fixes this so tools like `htop` and `free` report the actual container limit.

lxcfs ships with Ubuntu but won't start on WSL2 due to a systemd condition (`ConditionVirtualization=!container`). Override it once on the host:

```bash
sudo mkdir -p /etc/systemd/system/lxcfs.service.d

sudo tee /etc/systemd/system/lxcfs.service.d/override.conf > /dev/null << 'EOF'
[Unit]
ConditionVirtualization=
EOF

sudo systemctl daemon-reload
sudo systemctl start lxcfs
```

Then restart the container:

```bash
incus restart <name>
```

## Common Commands

```bash
incus shell <name>          # shell into container
incus list                  # list containers
incus info <name>           # resource usage
incus config show <name>    # full config
incus restart <name>        # restart
incus stop <name>           # stop
incus delete <name> --force # delete
```
