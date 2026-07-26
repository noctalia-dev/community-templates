#!/usr/bin/env bash
set -euo pipefail

config_dir_xdg="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
config_file="$config_dir_xdg/config.jsonc"
theme_file="$config_dir_xdg/themes/noctalia.jsonc"

mkdir -p "$config_dir_xdg"
[ -f "$config_file" ] || echo '{ "modules": [] }' >"$config_file"

if [ ! -f "$theme_file" ]; then
    echo "Warning: fastfetch theme file not found: $theme_file" >&2
    exit 0
fi

# Compare only the "logo"/"display" sub-objects semantically (jq -S, sorted+canonical),
# not the whole file's raw bytes -- jq's own re-serialization would never byte-match
# hand-formatted JSON, which made a naive cmp-the-whole-file guard fire on every single
# apply regardless of whether colors actually changed.
current_logo="$(jq -S '.logo // {}' "$config_file" 2>/dev/null || echo '{}')"
current_display="$(jq -S '.display // {}' "$config_file" 2>/dev/null || echo '{}')"
new_logo="$(jq -S '.logo // {}' "$theme_file")"
new_display="$(jq -S '.display // {}' "$theme_file")"

if [ "$current_logo" != "$new_logo" ] || [ "$current_display" != "$new_display" ]; then
    tmp_file="$(mktemp)"
    jq -s '.[0] * .[1]' "$config_file" "$theme_file" >"$tmp_file"
    cat "$tmp_file" >"$config_file"
    rm -f "$tmp_file"
fi
