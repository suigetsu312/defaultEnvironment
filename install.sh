#!/usr/bin/env bash

# Ensure this script runs with bash even if invoked via `sh`.
# This avoids errors like: `set: Illegal option -o pipefail` on POSIX sh.
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

# Safe bash defaults
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

info() { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

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

  if [ -L "$target" ]; then
    warn "Leaving existing symlink unchanged: $target"
    return 0
  fi
  if [ -f "$target" ] && cmp -s "$source" "$target"; then
    info "$target is already up to date"
    return 0
  fi

  backup_file "$target"
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

preflight_file() {
  local source=$1
  local target=$2

  if [ -L "$target" ]; then
    info "Preflight: preserving existing symlink $target"
  elif [ -f "$target" ] && cmp -s "$source" "$target"; then
    info "Preflight: $target already exists and is up to date"
  elif [ -e "$target" ]; then
    info "Preflight: $target exists; it will be backed up before updating"
  else
    info "Preflight: $target is missing and will be installed"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

info "Checking existing configuration before installation"
preflight_file zshrc.example "$HOME/.zshrc"
preflight_file p10k.zsh.example "$HOME/.p10k.zsh"
preflight_file shell-functions.zsh "$HOME/.config/defaultenv/shell-functions.zsh"
preflight_file scripts/tmux-copy.sh "$HOME/.local/lib/defaultenv/tmux-copy.sh"
preflight_file scripts/tmux-lazygit.sh "$HOME/.local/lib/defaultenv/tmux-lazygit.sh"
preflight_file nvim/init.lua "$HOME/.config/nvim/init.lua"
preflight_file nvim/lazy-lock.json "$HOME/.config/nvim/lazy-lock.json"
preflight_file tmux.conf.example "$HOME/.tmux.conf"

if require_cmd apt-get; then
  base_packages=(ca-certificates curl git zsh tmux neovim fzf zoxide xdg-utils fontconfig)
  missing_packages=()
  for package in "${base_packages[@]}"; do
    if dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx installed; then
      info "Preflight: package $package is already installed"
    else
      info "Preflight: package $package is missing"
      missing_packages+=("$package")
    fi
  done

  if [ "${#missing_packages[@]}" -gt 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      info "Caching sudo credentials (if prompted, enter your password)"
      sudo -v
      info "Updating apt index and installing missing packages"
      sudo apt-get update -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_packages[@]}"
    else
      err "sudo is required to install missing apt packages: ${missing_packages[*]}"
      exit 1
    fi
  else
    info "All required apt packages are already installed; skipping apt update/install"
  fi

  if require_cmd lazygit; then
    info "Preflight: lazygit is already installed"
  elif apt-cache show lazygit >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
      info "Preflight: lazygit is missing; installing it"
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y lazygit
    else
      warn "lazygit is available but sudo is unavailable; install it manually if needed."
    fi
  else
    warn "lazygit is not available in the configured apt repositories; install it separately if needed."
  fi
else
  warn "apt-get not found. Please install dependencies manually."
fi

# Install Oh My Zsh (unattended, don't switch shell now)
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
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
install_file shell-functions.zsh "$HOME/.config/defaultenv/shell-functions.zsh"

TMUX_HELPER_DIR="$HOME/.local/lib/defaultenv"
install_file scripts/tmux-copy.sh "$TMUX_HELPER_DIR/tmux-copy.sh"
install_file scripts/tmux-lazygit.sh "$TMUX_HELPER_DIR/tmux-lazygit.sh"

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
info "Checking MesloLGS Nerd Fonts"
FONT_DIR="$HOME/.local/share/fonts/MesloLGS-NF"
mkdir -p "$FONT_DIR"
for font in "Regular" "Bold" "Italic" "Bold Italic"; do
  encoded_font=${font// /%20}
  font_file="$FONT_DIR/MesloLGS%20NF%20${encoded_font}.ttf"
  if [ -s "$font_file" ]; then
    info "Preflight: Meslo font $font already exists"
  else
    info "Installing missing Meslo font: $font"
    curl -fsSL -o "$font_file" \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${encoded_font}.ttf"
  fi
done
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
  if nvm ls --no-colors 'lts/*' 2>/dev/null | grep -Eq 'v[0-9]+\.'; then
    info "Preflight: a Node.js LTS version is already installed"
  else
    info "Installing missing Node.js LTS via nvm"
    nvm install --lts
  fi
  nvm alias default 'lts/*'
  if require_cmd npm; then
    missing_npm_packages=()
    for package in yarn instant-markdown-d; do
      if npm list -g --depth=0 "$package" >/dev/null 2>&1; then
        info "Preflight: global npm package $package is already installed"
      else
        info "Preflight: global npm package $package is missing"
        missing_npm_packages+=("$package")
      fi
    done
    if [ "${#missing_npm_packages[@]}" -gt 0 ]; then
      npm install -g "${missing_npm_packages[@]}"
    fi
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
  nvim --headless "+Lazy! sync" +qa || warn "Neovim plugin installation had non-fatal issues."
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
