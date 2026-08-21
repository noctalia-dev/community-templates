#!/usr/bin/env bash
set -euo pipefail

theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/themes/noctalia.conf"

if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: tmux is not installed" >&2
  exit 1
fi

if [ ! -f "$theme_file" ]; then
  echo "Error: rendered tmux theme not found at $theme_file" >&2
  exit 1
fi

if tmux list-sessions >/dev/null 2>&1; then
  tmux source-file "$theme_file"
fi
