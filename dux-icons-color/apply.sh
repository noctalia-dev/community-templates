#!/usr/bin/env bash

set -euo pipefail

palette="${XDG_CACHE_HOME:-$HOME/.cache}/dux-icons/noctalia-palette.json"

if ! command -v dux-icons >/dev/null 2>&1; then
  echo "dux-icons: command not found in PATH, install Dux Icons first" >&2
  exit 1
fi

if [ ! -f "$palette" ]; then
  echo "dux-icons: palette not found at $palette" >&2
  exit 1
fi

exec dux-icons --palette "$palette" --files-style color
