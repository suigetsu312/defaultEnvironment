#!/usr/bin/env bash

# Ensure this script runs with bash even if invoked via `sh`.
# This avoids errors like: `set: Illegal option -o pipefail` on POSIX sh.
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

# Safe bash defaults
set -euo pipefail

info() { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

usage() {
  cat <<EOF
Usage: bash install.sh [--force]

By default, existing dotfiles are left untouched. Use --force to back up and
replace managed dotfiles such as ~/.zshrc, ~/.p10k.zsh, ~/.config/nvim/init.lua,
and ~/.tmux.conf.
EOF
}

FORCE=${FORCE:-0}
for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown option: $arg"
      usage
      exit 2
      ;;
  esac
done

backup_file() {
  local target=$1
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    cp -f "$target" "${target}.bak.${ts}"
    warn "Backed up $target to ${target}.bak.${ts}"
  fi
}

install_file() {
  local source=$1
  local target=$2

  if [ -e "$target" ] && cmp -s "$source" "$target"; then
    info "$target already up to date"
    return
  fi

  if [ -e "$target" ] && [ "$FORCE" != "1" ]; then
    warn "$target already exists; use --force to back up and replace it."
    return
  fi

  backup_file "$target"
  cp -f "$source" "$target"
  info "Installed $target"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

# Keep sudo alive (if available)
if command -v sudo >/dev/null 2>&1; then
  info "Caching sudo credentials (if prompted, enter your password)"
  sudo -v || true
fi

info "Updating apt package index and installing base packages"
if require_cmd apt-get; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl git zsh tmux neovim xdg-utils fontconfig
else
  warn "apt-get not found. Please install dependencies manually."
fi

# Install Oh My Zsh (unattended, don't switch shell now)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh (unattended)"
  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  info "Oh My Zsh already installed"
fi

# Powerlevel10k theme
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]; then
  info "Installing Powerlevel10k theme"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
else
  info "Powerlevel10k already installed"
fi

# Copy dotfiles with backup
info "Installing zsh and Powerlevel10k configs"
install_file zshrc.example "$HOME/.zshrc"
install_file p10k.zsh.example "$HOME/.p10k.zsh"

# Set default shell to zsh if needed
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
  if command -v chsh >/dev/null 2>&1; then
    info "Setting default shell to zsh (you may need to log out/in)"
    chsh -s "$(command -v zsh)" || warn "Could not change default shell automatically."
  else
    warn "'chsh' not found; set default shell to zsh manually."
  fi
fi

# Install Meslo Nerd Fonts locally for P10k
info "Installing MesloLGS Nerd Font locally"
FONT_DIR="$HOME/.local/share/fonts/MesloLGS-NF"
mkdir -p "$FONT_DIR"
curl -fsSL -o "$FONT_DIR/MesloLGS NF Regular.ttf" \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl -fsSL -o "$FONT_DIR/MesloLGS NF Bold.ttf" \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl -fsSL -o "$FONT_DIR/MesloLGS NF Italic.ttf" \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl -fsSL -o "$FONT_DIR/MesloLGS NF Bold Italic.ttf" \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$HOME/.local/share/fonts" || true
fi

# NVM + Node.js LTS + Yarn + instant-markdown-d
if [ ! -d "$HOME/.nvm" ]; then
  info "Installing nvm"
  export NVM_DIR="$HOME/.nvm"
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  (
    cd "$NVM_DIR"
    git checkout "$(git describe --abbrev=0 --tags --match 'v[0-9]*' $(git rev-list --tags --max-count=1))"
  )
else
  info "nvm already installed"
fi

# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if require_cmd nvm; then
  info "Installing Node.js LTS via nvm"
  nvm install --lts
  nvm alias default 'lts/*'
  # Ensure npm and yarn, then markdown preview server
  if require_cmd npm; then
    info "Installing global npm packages (yarn, instant-markdown-d)"
    npm install -g yarn instant-markdown-d
  fi
else
  warn "nvm not available in current shell; skip Node.js installation."
fi

# Neovim config (init.lua + lazy-lock)
info "Installing Neovim configuration"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_CONFIG_DIR"
install_file nvim/init.lua "$NVIM_CONFIG_DIR/init.lua"
install_file nvim/lazy-lock.json "$NVIM_CONFIG_DIR/lazy-lock.json"

# Install Neovim plugins headlessly (optional but handy)
if command -v nvim >/dev/null 2>&1; then
  info "Installing Neovim plugins (non-interactive)"
  nvim --headless "+Lazy! restore" +qa || warn "Neovim plugin installation had non-fatal issues."
else
  warn "Neovim not found in PATH; skipping plugin installation."
fi

# Tmux config
info "Installing tmux configuration"
install_file tmux.conf.example "$HOME/.tmux.conf"

cat <<'EOM'

Done!

Next steps:
- Set your terminal font to "MesloLGS NF" for best Powerlevel10k appearance.
- Restart your terminal session (or log out/in) to apply the default shell change.
- In zsh, you can run `p10k configure` to tweak your prompt.

EOM
