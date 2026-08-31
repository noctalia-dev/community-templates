#!/usr/bin/env bash
set -euo pipefail

# Fall back to the passwd entry if $HOME wasn't handed to us at all.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
config_file="$config_dir/jay/config.toml"
theme_file="$cache_dir/noctalia/templates/jay-theme.toml"

if [ ! -f "$config_file" ]; then
  echo "ERROR: jay config not found at $config_file"
  exit 1
fi

if [ ! -f "$theme_file" ]; then
  echo "ERROR: rendered theme fragment not found at $theme_file"
  exit 1
fi

fragment="$(cat "$theme_file")"

if ! grep -q '^\[theme\]' "$config_file"; then
  # No [theme] table yet at all — cheap append, nothing to merge with.
  printf '\n%s\n' "$fragment" >>"$config_file"
  echo "OK: appended theme (first run)"
  exit 0
fi

# The key names our fragment defines (ignoring the [theme] header itself,
# comments, and blank lines). Only these keys get touched inside an
# existing [theme] table — anything else the user put there is kept as-is.
managed_keys="$(printf '%s\n' "$fragment" |
  grep -E '^[A-Za-z0-9_-]+[[:space:]]*=' |
  sed -E 's/^([A-Za-z0-9_-]+).*/\1/' |
  paste -sd'|' -)"
echo "managed_keys=$managed_keys"

tmp="$(mktemp "$config_dir/jay/config.toml.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

awk -v frag="$fragment" -v keys="$managed_keys" '
    BEGIN { keypat = "^(" keys ")[[:space:]]*=" }
    !replaced && /^\[theme\]/ {
        print frag
        replaced = 1
        in_theme = 1
        next
    }
    in_theme && /^\[/ && !/^\[theme\]/ && !/^\[theme\./ { in_theme = 0 }
    in_theme {
        if ($0 ~ keypat) next   # one of ours — already emitted via frag
        print                   # user-defined key, comment, or blank line
        next
    }
    { print }
    END { if (!replaced) { print ""; print frag } }
' "$config_file" >"$tmp"

mv "$tmp" "$config_file"
echo "OK: theme merged"
