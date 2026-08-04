#!/usr/bin/env sh

set -eu

conf_file="${XDG_CONFIG_HOME:-$HOME/.config}/rio/config.toml"

if [ ! -f "$conf_file" ]; then
    echo 'theme = "noctalia"' > "$conf_file"
    exit 0
fi

if grep -q '^[[:space:]]*theme[[:space:]]*=[[:space:]]*"noctalia"' "$conf_file"; then
    exit 0
elif grep -q '^[[:space:]]*theme[[:space:]]*=.*'; then
    sed -i 's/^[[:space:]]*theme[[:space:]]*=.*/theme = "noctalia"/' "$conf_file"
else
    sed -i '1i theme = "noctalia"' "$conf_file"
fi
