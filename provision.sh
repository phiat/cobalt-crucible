#!/bin/bash
set -e

# Suppress apt warnings and interactive prompts
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export SYSTEMD_PAGER=

# Progress tracking
TOTAL_STEPS=13
CURRENT_STEP=0

progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n[$CURRENT_STEP/$TOTAL_STEPS] $1"
}

complete() {
    echo "✓ Done"
}

error() {
    echo "❌ Error: $1"
    exit 1
}

progress "⏳ Updating system"
apt-get update -qq > /dev/null 2>&1 || error "Failed to update system"
apt-get upgrade -y -qq > /dev/null 2>&1 || error "Failed to upgrade system"
complete

progress "⏳ Installing base packages"
apt-get install -y -qq curl wget git vim nano htop build-essential \
  net-tools iputils-ping dnsutils tmux zsh ca-certificates \
  gnupg lsb-release software-properties-common fzf tree \
  libssl-dev pkg-config libncurses5-dev openssh-server > /dev/null 2>&1 || error "Failed to install base packages"

# Enable and start SSH
systemctl enable ssh > /dev/null 2>&1
systemctl start ssh > /dev/null 2>&1
complete

progress "⏳ Installing GitHub CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg 2>/dev/null | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null 2>&1
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq gh > /dev/null 2>&1 || error "Failed to install GitHub CLI"
complete

progress "⏳ Installing Podman"
apt-get install -y -qq podman > /dev/null 2>&1 || error "Failed to install Podman"
complete

progress "⏳ Installing Tailscale"
curl -fsSL https://tailscale.com/install.sh 2>/dev/null | sh > /dev/null 2>&1 || error "Failed to install Tailscale"
complete

progress "⏳ Installing mise"
curl -sSf https://mise.run 2>/dev/null | sh > /dev/null 2>&1 || error "Failed to install mise"
complete

progress "⏳ Installing Oh My Zsh"
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 2>/dev/null)" > /dev/null 2>&1
# Verify it installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    error "Oh My Zsh installation failed"
fi
complete

progress "⏳ Configuring zsh"
cat > /root/.zshrc << 'EOF'
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# mise
eval "$(~/.local/bin/mise activate zsh)"

# Erlang shell history
export ERL_AFLAGS="-kernel shell_history enabled"

# fzf key bindings
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
EOF

chsh -s "$(which zsh)" > /dev/null 2>&1

# tmux config
cat > /root/.tmux.conf << 'EOF'
set-option -sg escape-time 10
set-option -g default-terminal "screen-256color"

bind r source-file ~/.tmux.conf

set -g visual-activity off
set -g visual-bell off
set -g visual-silence off
setw -g monitor-activity off
set -g bell-action none

set -g pane-border-style 'fg=maroon'
set -g pane-active-border-style 'fg=cyan'

set -g status-position top
set -g status-justify left
set -g status-style 'fg=cyan'

set -g status-left ''

set -g mouse on
EOF

# Ensure UTF-8 locale for powerline glyphs
locale-gen en_US.UTF-8 > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 > /dev/null 2>&1

complete

progress "⏳ Installing tools via mise (binary downloads, parallel)"
export PATH="$HOME/.local/bin:$PATH"
export MISE_PATH="$HOME/.local/bin/mise"

echo "  → Batch installing binary tools..."
$MISE_PATH use -g --jobs 4 \
  node@lts go@latest rust@latest zig@latest \
  bun@latest jq@latest bat@latest typst@latest \
  lazydocker@latest java@openjdk clojure@latest \
  yarn@latest ripgrep@latest fd@latest just@latest \
  > /dev/null 2>&1 || error "Failed to install binary tools"
complete

progress "⏳ Installing source-compiled tools via mise (slower)"
echo "  → Installing Erlang..."
$MISE_PATH use -g erlang@latest 2>&1 | grep -v "^mise" || true

echo "  → Installing Elixir (latest)..."
$MISE_PATH use -g elixir@latest > /dev/null 2>&1 || error "Failed to install Elixir"

echo "  → Installing Python (latest)..."
$MISE_PATH use -g python@latest > /dev/null 2>&1 || error "Failed to install Python"

complete

progress "⏳ Installing Claude Code"
eval "$($MISE_PATH activate bash)"
npm install -g @anthropic-ai/claude-code > /dev/null 2>&1 || error "Failed to install Claude Code"
complete

progress "⏳ Installing OpenCode"
curl -fsSL https://opencode.ai/install 2>/dev/null | bash > /dev/null 2>&1 || error "Failed to install OpenCode"
complete

progress "⏳ Verifying installations"
eval "$($MISE_PATH activate bash)"
echo "  • Node: $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "  • Go: $(go version 2>/dev/null | awk '{print $3}' || echo 'NOT FOUND')"
echo "  • Rust: $(rustc --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • Erlang: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo 'NOT FOUND')"
echo "  • Elixir: $(elixir --version 2>/dev/null | grep Elixir | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • Java: $(java --version 2>/dev/null | head -n1 || echo 'NOT FOUND')"
echo "  • Clojure: $(clojure --version 2>/dev/null || echo 'NOT FOUND')"
echo "  • Zig: $(zig version 2>/dev/null || echo 'NOT FOUND')"
echo "  • Python: $(python --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • Bun: $(bun --version 2>/dev/null || echo 'NOT FOUND')"
echo "  • jq: $(jq --version 2>/dev/null || echo 'NOT FOUND')"
echo "  • bat: $(bat --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • typst: $(typst --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • lazydocker: $(lazydocker --version 2>/dev/null | awk '{print $4}' || echo 'NOT FOUND')"
echo "  • yarn: $(yarn --version 2>/dev/null || echo 'NOT FOUND')"
echo "  • ripgrep: $(rg --version 2>/dev/null | head -n1 | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • fd: $(fd --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • just: $(just --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • gh: $(gh --version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'NOT FOUND')"
echo "  • tree: $(tree --version 2>/dev/null | awk '{print $2}' || echo 'NOT FOUND')"
echo "  • mise: $($MISE_PATH --version 2>/dev/null || echo 'NOT FOUND')"
complete

echo -e "\n🎉 Installation complete!"
echo "Exit and re-enter to use zsh with all tools configured"
echo ""
echo "Installed tools managed by mise:"
echo "  • Run 'mise ls' to see installed versions"
echo "  • Run 'mise use <tool>@<version>' to install other versions"
