#!/usr/bin/env bash
set -euo pipefail

config_dir_xdg="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
config_file="$config_dir_xdg/config.jsonc"
theme_file="$config_dir_xdg/themes/noctalia.jsonc"

if [ ! -f "$config_file" ]; then
    echo "Error: fastfetch config not found at $config_file -- run fastfetch once to generate a default config first." >&2
    exit 1
fi

if [ ! -f "$theme_file" ]; then
    echo "Warning: fastfetch theme file not found: $theme_file" >&2
    exit 0
fi

# jq only accepts strict JSON. config.jsonc is JSONC (comments/trailing commas allowed), so
# fail loudly with a clear message rather than let a bare jq parse error explain nothing, or
# silently skip and leave the user without any indication why colors never apply.
if ! jq empty "$config_file" 2>/dev/null; then
    echo "Error: $config_file could not be parsed as strict JSON. Comments and trailing commas (valid JSONC, not valid JSON) are not currently supported by this hook -- remove them to use this template." >&2
    exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

# Compare only the "logo"/"display" sub-objects semantically (jq -S, sorted+canonical),
# not the whole file's raw bytes -- jq's own re-serialization would never byte-match
# hand-formatted JSON, which made a naive cmp-the-whole-file guard fire on every single
# apply regardless of whether colors actually changed.
current_logo="$(jq -S '.logo // {}' "$config_file")"
current_display="$(jq -S '.display // {}' "$config_file")"
new_logo="$(jq -S '.logo // {}' "$theme_file")"
new_display="$(jq -S '.display // {}' "$theme_file")"

if [ "$current_logo" != "$new_logo" ] || [ "$current_display" != "$new_display" ]; then
    jq -s '.[0] * .[1]' "$config_file" "$theme_file" >"$tmp_file"
    cat "$tmp_file" >"$config_file"
fi
