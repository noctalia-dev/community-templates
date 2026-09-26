#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/go-musicfox"
config_file="$config_dir/config.toml"
theme_name="Noctalia"

# Nothing to patch until musicfox has written its config (run musicfox once).
# The theme file is still rendered; it activates on the next theme change.
if [ ! -f "$config_file" ]; then
    echo "musicfox: config.toml not found at $config_file; run musicfox once" >&2
    exit 0
fi

# Idempotent: already selected. A trailing comment after the value is fine.
if grep -Eq "^[[:space:]]*activeTheme[[:space:]]*=[[:space:]]*\"$theme_name\"[[:space:]]*(#.*)?$" "$config_file"; then
    exit 0
fi

# 1) An activeTheme line exists (anywhere, once): rewrite the whole
#    assignment as activeTheme = "Noctalia", keeping any trailing
#    comment; indentation and spacing around the key are normalized. Handles
#    double- and single-quoted values. awk is used (not sed) because sed's
#    '0,/re/' range and '\s' are GNU extensions that fail on BSD/macOS and
#    busybox; awk patterns use POSIX [[:space:]]. Write through the existing
#    file so symlinks, permissions, and inode survive.
if grep -Eq '^[[:space:]]*activeTheme[[:space:]]*=' "$config_file"; then
    tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
    awk -v theme="$theme_name" -v q="'" '
        /^[[:space:]]*activeTheme[[:space:]]*=/ && !done {
            sub(/^[[:space:]]*activeTheme[[:space:]]*=[[:space:]]*"[^"]*"/, "activeTheme = \"" theme "\"")
            sub("^[[:space:]]*activeTheme[[:space:]]*=[[:space:]]*" q "[^" q "]*" q, "activeTheme = \"" theme "\"")
            print
            done = 1
            next
        }
        { print }
    ' "$config_file" > "$tmp_file"
    cat "$tmp_file" > "$config_file"
    rm -f "$tmp_file"
    exit 0
fi

# 2) No activeTheme key, but a [theme] section: insert the key after the
#    header's leading comment/blank lines, before the first real setting.
if grep -q '^[[:space:]]*\[theme\]' "$config_file"; then
    tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
    awk -v line="activeTheme = \"$theme_name\"" '
        /^[[:space:]]*\[theme\]/ && !done { print; done = 1; in_section = 1; next }
        in_section && /^[[:space:]]*#/ { print; next }
        in_section && /^[[:space:]]*$/ { print; next }
        in_section { print line; in_section = 0 }
        { print }
        END { if (in_section) print line }
    ' "$config_file" > "$tmp_file"
    cat "$tmp_file" > "$config_file"
    rm -f "$tmp_file"
    exit 0
fi

# 3) No [theme] section at all: append a minimal one.
printf '\n[theme]\nactiveTheme = "%s"\n' "$theme_name" >> "$config_file"
