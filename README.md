# cobalt-crucible

Automated setup for Ubuntu 24.04 development containers using Incus on Ubuntu 24.04 running in WSL2.

This provisions isolated, resource-limited Ubuntu 24.04 containers from your Ubuntu 24.04 WSL2 host. Each container includes a full polyglot dev environment (Node, Go, Rust, Erlang, Elixir, Python, Java, Clojure, Zig, Bun) managed by mise, plus Podman, Tailscale, Claude Code, OpenCode, and a configured zsh/tmux setup.

**Use case**: Spin up clean, reproducible dev environments in seconds (after first build), snapshot them for reuse, and enforce resource limits (memory/CPU) per container.

## Setup

```bash
# 1. Install Incus
sudo apt install incus
sudo incus admin init --auto

# 2. Fix lxcfs for WSL2 (recommended)
# This fixes resource reporting inside containers. Without it, tools like htop
# and free show host memory instead of container limits. Only needed once per WSL2 host.
sudo apt install lxcfs
sudo mkdir -p /etc/systemd/system/lxcfs.service.d

sudo tee /etc/systemd/system/lxcfs.service.d/override.conf > /dev/null << 'EOF'
[Unit]
ConditionVirtualization=
EOF

sudo systemctl daemon-reload
sudo systemctl start lxcfs

# lxcfs won't start on WSL2 without the override because systemd detects
# WSL2 as a container environment and skips it.

# 3. Build the container
# This takes 15-20 minutes (Erlang compiles from source)
git clone https://github.com/phiat/cobalt-crucible.git
cd cobalt-crucible
bash setup.sh my-dev ./provision.sh
```

Then shell in:

```bash
incus shell my-dev
```

Rename the container (optional):

```bash
incus rename my-dev new-name
```

## What Gets Installed

`provision.sh` provisions the container with:

- **System**: build-essential, curl, wget, git, htop, tmux, tree, net-tools, etc.
- **Shell**: zsh + Oh My Zsh (agnoster theme), tmux (maroon/cyan theme, mouse on, status top)
- **Languages** (via mise): Node.js, Go, Rust, Erlang, Elixir, Python, Java, Clojure, Zig, Bun
- **CLI tools** (via mise): jq, bat, typst, lazydocker, yarn, ripgrep, fd, just
- **Containers**: Podman
- **Networking**: Tailscale
- **Dev tools**: Claude Code, OpenCode, GitHub CLI (gh), fzf

## Snapshots

After building, save the container as a reusable image so future containers launch in seconds:

```bash
incus stop my-dev
incus publish my-dev --alias cobalt-crucible-base
incus start my-dev
```

Launch from snapshot:

```bash
incus launch cobalt-crucible-base <name>
```

Update the snapshot after making changes:

```bash
incus stop <name>
incus image delete cobalt-crucible-base
incus publish <name> --alias cobalt-crucible-base
incus start <name>
```

## Resource Limits

Defaults are set in `setup.sh` (8GB memory, 8 CPUs). Adjust per container:

```bash
incus config set <name> limits.memory 4GB
incus config set <name> limits.cpu 2
incus config set <name> limits.cpu.allowance 50%
incus config device set <name> root size=20GB
```

Changes apply live — no restart needed.

## Common Commands

```bash
incus shell <name>          # shell into container
incus list                  # list containers
incus info <name>           # resource usage
incus config show <name>    # full config
incus rename <old> <new>    # rename container
incus restart <name>        # restart
incus stop <name>           # stop
incus delete <name> --force # delete
incus image list            # list local images
```
