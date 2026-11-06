#!/usr/bin/env bash
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/iamb/config.toml"
[[ -f "$CONFIG" ]] || { echo "iamb config not found: $CONFIG" >&2; exit 1; }

tmp=$(mktemp "${CONFIG}.XXXXXX")
trap 'rm -f "$tmp"' EXIT

awk -v sq="'" -v new='theme = "noctalia"' '
skip {                                    # inside a multiline theme value
    if (index($0, end)) skip = 0
    next
}
/^[[:space:]]*\[/ {                       # table header
    if (in_settings) {
        if (!done) { print new; done = 1 }
        printf "%s", pending; pending = ""
    }
    in_settings = /^[[:space:]]*\[settings\][[:space:]]*(#.*)?$/
    if (in_settings) found = 1
    print; next
}
in_settings && /^[[:space:]]*(#.*)?$/ {   # hold blanks/comments until we know what follows
    pending = pending $0 "\n"; next
}
in_settings && /^[[:space:]]*theme[[:space:]]*=/ {
    printf "%s", pending; pending = ""
    if (!done) { print new; done = 1 }    # replace in place, drop duplicates
    if (split($0, p, "\"\"\"") - 1 == 1)      { skip = 1; end = "\"\"\"" }
    else if (split($0, p, sq sq sq) - 1 == 1) { skip = 1; end = sq sq sq }
    next
}
in_settings { printf "%s", pending; pending = "" }
{ print }
END {
    if (in_settings) {
        if (!done) print new
        printf "%s", pending
    }
    if (!found) { if (NR) print ""; print "[settings]"; print new }
}
' "$CONFIG" > "$tmp"

cat "$tmp" > "$CONFIG"
