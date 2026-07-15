#!/usr/bin/env bash
set -euo pipefail

bat_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bat"
themes_dir="$bat_config_dir/themes"
config_file="$bat_config_dir/config"
theme_file="$themes_dir/noctalia.tmTheme"
theme_line="--theme=noctalia"

mkdir -p "$themes_dir"
touch "$config_file" "$theme_file"

if ! grep -Fxq -- "$theme_line" "$config_file"; then
    sed -i '/^--theme=/d' "$config_file"
    [ -s "$config_file" ] && [ -n "$(tail -c1 "$config_file")" ] && echo >>"$config_file"
    printf '%s\n' "$theme_line" >>"$config_file"
fi

if command -v bat >/dev/null 2>&1; then
    bat cache --build
elif command -v batcat >/dev/null 2>&1; then
    batcat cache --build
else
    echo "Warning: 'bat' executable not found. Please run 'bat cache --build' manually once it is installed."
fi
