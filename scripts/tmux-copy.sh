#!/bin/sh

if [ -n "${WSL_INTEROP:-}" ] && command -v clip.exe >/dev/null 2>&1; then
  exec clip.exe
fi
if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy
fi
if [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
  exec xclip -selection clipboard
fi
if [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
  exec xsel --clipboard --input
fi

cat >/dev/null
printf '%s\n' 'tmux: no system clipboard utility is available; selection remains in the tmux buffer.' >&2
