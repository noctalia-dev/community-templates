#!/usr/bin/env bash
# Revert apply.sh: drop `theme = "noctalia"` from [general] in HyprFM's
# config.toml (HyprFM then follows its own light_theme/dark_theme pair again)
# and remove the rendered theme file. A no-op when there is nothing to revert.
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hyprfm"
config_file="$config_dir/config.toml"
theme_file="$config_dir/themes/noctalia.toml"

if [ -f "$config_file" ]; then
    tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
    trap 'rm -f "$tmp_file"' EXIT

    # Only a line that selects noctalia is removed; any other theme is the user's.
    awk '
        /^[[:space:]]*\[/ {
            in_general = ($0 ~ /^[[:space:]]*\[general\][[:space:]]*(#.*)?$/)
        }
        in_general && /^[[:space:]]*theme[[:space:]]*=[[:space:]]*["\047]noctalia["\047][[:space:]]*(#.*)?$/ { next }
        { print }
    ' "$config_file" >"$tmp_file"

    if ! cmp -s "$config_file" "$tmp_file"; then
        cat "$tmp_file" >"$config_file"
    fi
fi

rm -f -- "$theme_file"
