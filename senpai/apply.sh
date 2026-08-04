#!/usr/bin/env bash
set -euo pipefail

config_dir_xdg="${XDG_CONFIG_HOME:-$HOME/.config}/senpai"
config_file="$config_dir_xdg/senpai.scfg"
theme_file="$config_dir_xdg/themes/noctalia.scfg"

mkdir -p "$config_dir_xdg"
[ -f "$config_file" ] || touch "$config_file"

if [ ! -f "$theme_file" ]; then
    echo "Warning: senpai theme file not found: $theme_file" >&2
    exit 0
fi

theme_block="$(cat "$theme_file")"
tmp_file="$(mktemp)"

awk -v theme_data="$theme_block" '
BEGIN { in_colors = 0; depth = 0; saw_colors = 0 }
{
    if (!in_colors && $0 ~ /^colors[[:space:]]*\{[[:space:]]*$/) {
        in_colors = 1
        saw_colors = 1
        depth = 1
        print theme_data
        next
    }
    if (in_colors) {
        n = gsub(/\{/, "{"); depth += n
        n = gsub(/\}/, "}"); depth -= n
        if (depth <= 0) { in_colors = 0 }
        next
    }
    print
}
END {
    if (!saw_colors) {
        print ""
        print theme_data
    }
}
' "$config_file" >"$tmp_file"

if ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
fi
rm -f "$tmp_file"
