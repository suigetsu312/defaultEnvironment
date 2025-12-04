# Ubuntu/Linux Dev Environment

Opinionated setup for Ubuntu/Debian-based systems: zsh + Oh My Zsh, Powerlevel10k, Meslo Nerd Font, Neovim (with Lazy.nvim config), and tmux. The installer is idempotent and non-interactive.

---

## Quick Install

- Clone and run:

```sh
git clone https://github.com/suigetsu312/defaultEnvironment.git
cd defaultEnvironment
bash install.sh
```

- One-liner (remote):

```sh
curl -fsSL https://raw.githubusercontent.com/suigetsu312/defaultEnvironment/main/install.sh | bash
```

## What It Does

- zsh + Oh My Zsh: Installs Oh My Zsh unattended and sets zsh as default shell.
- Powerlevel10k: Installs theme and copies `~/.p10k.zsh` from `p10k.zsh.example`.
- Fonts: Installs MesloLGS Nerd Font locally and refreshes font cache.
- Neovim: Installs Neovim, copies `~/.config/nvim/init.lua` (and `lazy-lock.json`) from `nvim/`, and runs Lazy to install plugins headlessly.
- Node.js: Installs nvm, Node.js LTS, yarn, and `instant-markdown-d` globally.
- tmux: Copies `~/.tmux.conf` from `tmux.conf.example`.

## Requirements

- Ubuntu/Debian with `apt-get` and internet access.
- The script uses `sudo` for package installation.

## After Install

- Terminal font: Set the terminal font to "MesloLGS NF" for best Powerlevel10k appearance.
- New shell: Log out/in or restart the terminal to apply the zsh default shell.
- Prompt config: In zsh, run `p10k configure` to customize your prompt.

## Notes

- The installer backs up existing dotfiles it overwrites (e.g., `~/.zshrc.bak.YYYYMMDD-HHMMSS`).
- Re-running the installer is safe; it skips work that is already done.
