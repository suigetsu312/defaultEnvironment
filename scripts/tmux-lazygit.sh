#!/bin/sh

if command -v lazygit >/dev/null 2>&1; then
  exec lazygit
fi

printf '%s\n' 'lazygit is not installed. Install it to use this shortcut.' 'Press Enter to close.'
IFS= read -r _
