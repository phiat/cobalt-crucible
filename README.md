# inco-fi

Incus dev container setup for WSL2.

## Quick Start

```bash
./create-dev-container.sh <name> ./dev-setup.sh
```

This launches an Ubuntu 24.04 container, applies resource limits, and runs the setup script inside it.

## What Gets Installed

`dev-setup.sh` provisions the container with:

- **System**: build-essential, curl, wget, git, htop, tmux, net-tools, etc.
- **Shell**: zsh + Oh My Zsh (robbyrussell theme)
- **Languages** (via mise): Node.js, Go, Rust, Erlang, Elixir, Java, Clojure, Zig
- **Containers**: Podman
- **Networking**: Tailscale
- **Dev tools**: Claude Code, OpenCode, fzf

## Resource Limits

Set in `create-dev-container.sh` after launch (applied live, no restart needed):

| Resource | Limit | Config key |
|----------|-------|------------|
| Memory | 4GB (hard cap) | `limits.memory` |
| CPU | 2 cores | `limits.cpu` |

Adjust or add more:

```bash
incus config set <name> limits.memory 8GB
incus config set <name> limits.cpu 4
incus config set <name> limits.cpu.allowance 50%
incus config device set <name> root size=20GB
```

## lxcfs on WSL2

By default, `/proc/meminfo` inside the container reports host memory (e.g. 32GB) even with limits set. lxcfs fixes this so tools like `htop` and `free` report the actual container limit.

lxcfs ships with Ubuntu but won't start on WSL2 due to a systemd condition (`ConditionVirtualization=!container`). Override it:

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

`free -h` inside should now report the constrained memory.

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
