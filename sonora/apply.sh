#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    native)
        config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
        config_dir="$config_home/sonora"
        ;;
    flatpak)
        config_dir="$HOME/.var/app/io.github.nolight132.sonora/config/sonora"
        ;;
    *)
        echo "Usage: $0 {native|flatpak}" >&2
        exit 2
        ;;
esac

theme_file="$config_dir/noctalia-theme.json"
settings_file="$config_dir/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "Sonora template requires jq" >&2
    exit 1
fi

if [ ! -f "$theme_file" ]; then
    echo "Sonora theme file not found: $theme_file" >&2
    exit 1
fi

if [ ! -f "$settings_file" ]; then
    echo "Sonora settings not found: $settings_file (launch Sonora once first)" >&2
    exit 1
fi

temporary="$(mktemp "${settings_file}.tmp.XXXXXX")"
trap 'rm -f -- "$temporary"' EXIT

jq --indent 2 --slurpfile theme "$theme_file" \
    '.appearance = ((.appearance // {}) * $theme[0])' \
    "$settings_file" >"$temporary"
chmod --reference="$settings_file" "$temporary"

if cmp -s "$settings_file" "$temporary"; then
    rm -f "$temporary"
else
    mv "$temporary" "$settings_file"
fi
trap - EXIT
