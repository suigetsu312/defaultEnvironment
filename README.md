# macOS Dev Environment (iTerm2)

Opinionated setup for macOS: iTerm2, zsh + Oh My Zsh, Powerlevel10k, Meslo Nerd Font, Neovim (with Lazy.nvim config), and tmux. The installer is idempotent and non-interactive.

---

## Quick Install

- Clone and run:

```sh
git clone https://github.com/suigetsu312/defaultEnvironment.git
cd defaultEnvironment
git checkout macos
bash install.sh
# To replace existing dotfiles after backing them up:
bash install.sh --force
```

Note: this branch is macOS-only. Homebrew is installed automatically if missing.

## Usage on macOS

1) Open Terminal (or iTerm2) and clone the repo.
2) Switch to the `macos` branch.
3) Run the installer script.

```sh
git clone https://github.com/suigetsu312/defaultEnvironment.git
cd defaultEnvironment
git checkout macos
bash install.sh
# To replace existing dotfiles after backing them up:
bash install.sh --force
```

The script is safe to re-run. By default it skips existing dotfiles; pass `--force` to back them up and replace them with the repo-managed versions.

## What It Does

- iTerm2: Installs iTerm2 via Homebrew Cask.
- zsh + Oh My Zsh: Installs Oh My Zsh unattended and sets zsh as default shell.
- Powerlevel10k: Installs theme and copies `~/.p10k.zsh` from `p10k.zsh.example`.
- Fonts: Installs MesloLGS Nerd Font into `~/Library/Fonts`.
- Neovim: Installs Neovim, copies `~/.config/nvim/init.lua` (and `lazy-lock.json`) from `nvim/`, and runs Lazy restore to install plugins from `lazy-lock.json` headlessly.
- Node.js: Installs nvm, Node.js LTS, yarn, and `instant-markdown-d` globally.
- tmux: Copies `~/.tmux.conf` from `tmux.conf.example`.

## Requirements

- macOS with internet access.
- The script uses Homebrew for package installation.

## After Install

- iTerm2 font: Set the terminal font to "MesloLGS NF" for best Powerlevel10k appearance.
- New shell: Log out/in or restart the terminal to apply the zsh default shell.
- Prompt config: In zsh, run `p10k configure` to customize your prompt.

## Notes

- The installer skips existing dotfiles by default. With `--force`, it backs up files it overwrites (e.g., `~/.zshrc.bak.YYYYMMDD-HHMMSS`).
- Re-running the installer is safe; it skips work that is already done.
