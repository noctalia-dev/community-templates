#!/bin/sh
COLORS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/qutebrowser/noctalia/colors.py"

[ "$COLORS_FILE" -nt "$0" ] || exit 0
touch "$0"

pgrep -x qutebrowser >/dev/null && qutebrowser :config-source
