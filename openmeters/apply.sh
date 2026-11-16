#!/usr/bin/env bash
set -euo pipefail

operation="apply"
case "${1:-}" in
    native|flatpak)
        operation="apply"
        if [ "${1:-}" = "flatpak" ]; then
            config_dir="$HOME/.var/app/io.github.nolight132.openmeters/config/openmeters"
        else
            config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
            config_dir="$config_home/openmeters"
        fi
        ;;
    undo)
        operation="undo"
        config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
        config_dir="$config_home/openmeters"
        ;;
    *)
        echo "Usage: $0 {native|flatpak|undo}" >&2
        exit 2
        ;;
esac

theme_file="$config_dir/themes/noctalia.json"
settings_file="$config_dir/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "OpenMeters template requires jq" >&2
    exit 1
fi

if [ ! -f "$settings_file" ]; then
    echo "OpenMeters settings not found: $settings_file (launch OpenMeters once first)" >&2
    exit 1
fi

state_file="$config_dir/.openmeters-theme-previous"

if [ "$operation" = "apply" ]; then
    if [ ! -f "$theme_file" ]; then
        echo "OpenMeters theme file not found: $theme_file" >&2
        exit 1
    fi
    if [ ! -f "$state_file" ]; then
        had_theme="$(jq -r 'has("theme")' "$settings_file")"
        if [ "$had_theme" = "true" ]; then
            initial_theme="$(jq -r '.theme' "$settings_file")"
            printf '%s\n' "$(jq -cn --arg t "$initial_theme" '{had: true, theme: $t}')" >"$state_file"
        else
            printf '%s\n' '{"had":false,"theme":null}' >"$state_file"
        fi
    fi

    temporary="$(mktemp "${settings_file}.tmp.XXXXXX")"
    trap 'rm -f -- "$temporary"' EXIT

    jq --indent 2 '.theme = "noctalia"' "$settings_file" >"$temporary"
    chmod --reference="$settings_file" "$temporary"

    if cmp -s "$settings_file" "$temporary"; then
        rm -f -- "$temporary"
    else
        mv "$temporary" "$settings_file"
    fi
    trap - EXIT
else
    if [ ! -f "$state_file" ]; then
        exit 0
    fi
    state_theme="$(jq -r '.theme // empty' "$state_file")"
    state_had="$(jq -r '.had // false' "$state_file")"
    temporary="$(mktemp "${settings_file}.tmp.XXXXXX")"
    trap 'rm -f -- "$temporary"' EXIT
    if [ "$state_had" = "true" ]; then
        jq --arg theme "$state_theme" '.theme = $theme' "$settings_file" >"$temporary"
    else
        jq 'del(.theme)' "$settings_file" >"$temporary"
    fi
    chmod --reference="$settings_file" "$temporary"
    if cmp -s "$settings_file" "$temporary"; then
        rm -f -- "$temporary"
        rm -f -- "$state_file"
        trap - EXIT
        exit 0
    fi
    mv "$temporary" "$settings_file"
    rm -f -- "$state_file"
    trap - EXIT
fi
