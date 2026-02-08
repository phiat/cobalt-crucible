# cobalt-crucible

Incus dev container setup for WSL2.

## Setup

### 1. Install Incus

```bash
sudo apt install incus
sudo incus admin init --auto
```

### 2. Fix lxcfs for WSL2 (optional but recommended)

Without this, tools like `htop` and `free` inside containers report host memory instead of the container's limit. Only needed once per host.

```bash
sudo apt install lxcfs
sudo mkdir -p /etc/systemd/system/lxcfs.service.d

sudo tee /etc/systemd/system/lxcfs.service.d/override.conf > /dev/null << 'EOF'
[Unit]
ConditionVirtualization=
EOF

sudo systemctl daemon-reload
sudo systemctl start lxcfs
```

lxcfs won't start on WSL2 without the override because systemd detects WSL2 as a container environment and skips it.

### 3. Build the container

```bash
git clone https://github.com/phiat/cobalt-crucible.git
cd cobalt-crucible
bash create-dev-container.sh my-dev ./dev-setup.sh
```

This takes 15-20 minutes (Erlang compiles from source).

### 4. Shell in

```bash
incus shell my-dev
```

Claude Code and OpenCode require login after first launch:

```bash
claude login
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

Defaults are set in `create-dev-container.sh` (8GB memory, 8 CPUs). Adjust per container:

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
incus restart <name>        # restart
incus stop <name>           # stop
incus delete <name> --force # delete
incus image list            # list local images
```
