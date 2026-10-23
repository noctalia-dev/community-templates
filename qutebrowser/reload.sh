#!/bin/sh
COLORS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/qutebrowser/noctalia/colors.py"

[ "$COLORS_FILE" -nt "$0" ] || exit 0
touch "$0"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/qutebrowser"
ls "$RUNTIME_DIR"/ipc-* >/dev/null 2>&1 && qutebrowser :config-source
