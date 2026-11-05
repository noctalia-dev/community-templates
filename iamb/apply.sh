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
BEGIN { in_settings = 0; found = 0 }

/^[[:space:]]*\[/ {
    in_settings = ($0 ~ /^[[:space:]]*\[settings\][[:space:]]*$/)
}

in_settings && /^[[:space:]]*theme[[:space:]]*=/ {
    if (!found) {
        print "theme = \"noctalia\""
        found = 1
    }
    next
}

{ print }

END {
    if (!found) {
        print ""
        print "[settings]"
        print "theme = \"noctalia\""
    }
}
' "$CONFIG" > "$tmp"

cat "$tmp" > "$CONFIG"

