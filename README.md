# Ubuntu / Linux Developer Environment

This branch (`main`) targets Ubuntu/Debian, including Ubuntu on WSL2. It keeps
the existing Zsh + Oh My Zsh + Powerlevel10k and Neovim + lazy.nvim setup,
with Telescope retained as the Neovim file/search picker.

## Install and update

Requirements: Ubuntu/Debian with `apt-get`, internet access, and `sudo`.
The installer provides Zsh, tmux, Neovim, fzf, and zoxide. It installs
`lazygit` only when it is available in the configured apt repositories; otherwise
install lazygit separately to enable the optional Git window and popup.

```sh
git clone https://github.com/suigetsu312/defaultEnvironment.git
cd defaultEnvironment
git checkout main
bash install.sh
```

To update an existing checkout, run `git pull --ff-only` on `main`, then
`bash install.sh` again. Before installing, the script reports which apt
packages and configuration files already exist, skips installed packages, and
only downloads missing fonts. The installer copies configuration files (it does
not create symlinks); changed regular files are backed up with a timestamp
before replacement, identical files are left untouched, and existing symlinks
are preserved. tmux helper scripts are installed under
`~/.local/lib/defaultenv/`, and project functions under
`~/.config/defaultenv/`.

Restart Zsh or run `source ~/.zshrc` after installation. No OS release upgrade
or third-party apt repository is added.

## tmux

A **session** is a persistent workspace, a **window** is a tab within that
workspace, and a **pane** is a split terminal inside a window. The configuration
does not set a new Prefix; with tmux's default settings it remains `Ctrl+b`.

| Key | Action |
| --- | --- |
| Prefix + `h` / `j` / `k` / `l` | Move to left / down / up / right pane |
| Prefix + `z` | Maximize or restore the current pane (tmux's existing action) |
| Prefix + `c` | New window in the current pane's directory |
| Prefix + `"` / `%` | Split vertically / horizontally in the current directory |
| Prefix + `g` | lazygit popup (85%); tmux before 3.2 opens a window instead |
| Prefix + `r` | Reload `~/.tmux.conf` |
| Prefix + `[` | Enter Vi-style Copy Mode |
| Copy Mode `Space`, arrows/`h j k l`, `/`, `?`, `n`, `N` | Select, move, search, and navigate matches |
| Copy Mode `Enter` | Copy selection into tmux's buffer |
| Copy Mode `y` | Copy selection into tmux's buffer and try the system clipboard |

Copy Mode also retains tmux's Vi-style status keys. Clipboard integration tries
`pbcopy` on macOS, `clip.exe` in WSL2, `wl-copy` on Wayland, and `xclip` or
`xsel` on X11. Without a usable GUI clipboard (for example, headless Linux or
many SSH sessions), the tmux buffer still works; use Prefix + `]` to paste it.
OSC 52 is not enabled.

Use Prefix + `d` to detach without stopping the session. Reconnect with
`tmux attach-session -t SESSION`; list sessions with `tmux list-sessions`.
Reload manually with `tmux source-file ~/.tmux.conf`.

## Project workspaces

Zsh loads fzf's packaged key bindings/completion when available and initializes
zoxide only when installed. fzf's standard `Ctrl+r` history search remains
available; `zoxide` adds `z` and `zi` navigation.

- `tproject`: `zoxide query -l` → fzf selection → attach to or switch to the
  corresponding tmux session. Example: run `tproject`, type a project name,
  then press Enter. Pressing Escape cancels without changing sessions.
- `tlist`: choose an existing tmux session interactively.
- `tdev [directory]`: create or re-open a development workspace. For example:
  `tdev "$HOME/src/my project"`. It creates an `editor` window running Neovim,
  a `build` window with two shells, and a `git` window running lazygit when
  available (otherwise a regular shell). It does not run build commands.

Session names combine a sanitized directory basename and a portable `cksum` of
the absolute path, so same-named folders in different locations remain distinct.
When the session already exists, `tdev` and `tproject` reuse it and do not add
windows or change its pane layout. These functions require Zsh; project
selection additionally requires fzf, zoxide, and tmux.

## Neovim

The existing lazy.nvim configuration and Telescope remain in place. The
`vim-tmux-navigator` plugin provides `Ctrl+h/j/k/l` movement between Neovim
splits and tmux panes. Normal-mode navigation crosses the boundary; Insert-mode
`Ctrl+h` keeps its normal backspace behavior. No existing Neovim mapping was
reassigned.

## Troubleshooting and rollback

- **Session does not exist:** `tproject`/`tdev` create sessions automatically.
  For manual `tmux attach-session -t NAME`, first check `tmux list-sessions` or
  create the session with `tdev /path/to/project`.
- **Popup unsupported:** tmux 3.2 or newer provides Prefix + `g` popup mode;
  older versions use a regular tmux window. Check `tmux -V`.
- **fzf/zoxide missing:** install `fzf` and `zoxide` with apt, then restart
  Zsh. `tproject` prints a specific error if a required command is absent.
- **lazygit missing:** Prefix + `g` displays an install hint; `tdev` leaves the
  Git window as a shell. Install lazygit from a source appropriate to your
  distribution.
- **Clipboard unavailable:** install a clipboard utility for the active display
  server. WSL2 uses `clip.exe`; SSH/headless sessions can still use tmux's
  internal copy buffer. Remote clipboard forwarding is not automatic.
- **Shell initialization not active:** confirm `echo $SHELL` and start Zsh;
  check that `~/.zshrc` sources the installed
  `~/.config/defaultenv/shell-functions.zsh`.
- **Undo configuration deployment:** restore the timestamped `.bak.*` file
  created by the installer, or remove only the installed files listed above.
  Existing symlinks are never replaced.

Shell syntax, tmux configuration, fzf initialization, and project-session
behavior were tested on Ubuntu 24.04 in this environment. Full Neovim startup
is currently blocked by a pre-existing missing `nvim-treesitter.configs`
module in the installed plugin state. WSL2 and other Linux distributions have
not been tested here.
