#!/usr/bin/env bash
# Select the rendered theme: set `theme = "noctalia"` under [general] in
# HyprFM's config.toml. HyprFM watches config.toml and the active theme file,
# so open windows recolour live and nothing has to be signalled.
set -euo pipefail

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/hyprfm/config.toml"

if [ ! -f "$config_file" ]; then
    echo "Error: HyprFM config not found at $config_file -- start HyprFM once to create it." >&2
    exit 1
fi

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

# Rewrite general.theme and keep every other line as it is. A line that
# already selects noctalia stays untouched (HyprFM saves it single-quoted).
awk '
    function emit() { print "theme = \"noctalia\""; done = 1 }

    /^[[:space:]]*\[/ {
        if (in_general && !done) emit()
        in_general = ($0 ~ /^[[:space:]]*\[general\][[:space:]]*(#.*)?$/)
        if (in_general) seen_general = 1
        print
        next
    }
    in_general && /^[[:space:]]*theme[[:space:]]*=/ {
        if (done) next
        if ($0 ~ /^[[:space:]]*theme[[:space:]]*=[[:space:]]*["\047]noctalia["\047][[:space:]]*(#.*)?$/) {
            print
            done = 1
        } else {
            emit()
        }
        next
    }
    { print }
    END {
        if (in_general && !done) emit()
        if (!seen_general) { print ""; print "[general]"; emit() }
    }
' "$config_file" >"$tmp_file"

# Write through (a symlinked config stays a symlink), and only on a change.
if ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
fi
