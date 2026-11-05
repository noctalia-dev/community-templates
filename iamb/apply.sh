#!/usr/bin/env bash
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/iamb/config.toml"

if [[ ! -f "$CONFIG" ]]; then
    echo "iamb config not found: $CONFIG" >&2
    exit 1
fi

tmp=$(mktemp "${CONFIG}.XXXXXX")
trap 'rm -f "$tmp"' EXIT

awk '
BEGIN {
    in_settings = 0
    settings_found = 0
    theme_found = 0
}

/^[[:space:]]*\[/ {
    if (in_settings && !theme_found) {
        print "theme = \"noctalia\""
        theme_found = 1
    }

    in_settings = ($0 ~ /^[[:space:]]*\[settings\][[:space:]]*$/)

    if (in_settings)
        settings_found = 1
}

in_settings && /^[[:space:]]*theme[[:space:]]*=/ {
    if (!theme_found) {
        print "theme = \"noctalia\""
        theme_found = 1
    }
    next
}

{ print }

END {
    if (in_settings && !theme_found)
        print "theme = \"noctalia\""

    if (!settings_found) {
        print ""
        print "[settings]"
        print "theme = \"noctalia\""
    }
}
' "$CONFIG" > "$tmp"

cat "$tmp" > "$CONFIG"

