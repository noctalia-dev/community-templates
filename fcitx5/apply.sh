#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="$config_dir/fcitx5/conf/classicui.conf"
theme_name="noctalia"

mkdir -p "$(dirname "$config_file")"

write_if_changed() {
    local target="$1" tmp="$2"
    if [ ! -e "$target" ]; then
        mv "$tmp" "$target"
        return
    fi
    if ! cmp -s "$target" "$tmp"; then
        cat "$tmp" >"$target"
    fi
    rm -f "$tmp"
}

# Both modes use the same theme file, rendered with the current Noctalia palette.
for theme_key in Theme DarkTheme; do
    if [ ! -f "$config_file" ]; then
        echo "$theme_key=$theme_name" >"$config_file"
    elif grep -qE "^$theme_key=" "$config_file"; then
        if grep -qE "^$theme_key=$theme_name\$" "$config_file"; then
            :
        else
            tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
            sed -E "s/^$theme_key=.*/$theme_key=$theme_name/" "$config_file" >"$tmp_file"
            write_if_changed "$config_file" "$tmp_file"
        fi
    else
        [ -s "$config_file" ] && [ -n "$(tail -c1 "$config_file")" ] && echo >>"$config_file"
        echo "$theme_key=$theme_name" >>"$config_file"
    fi
done

busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui \
    >/dev/null 2>&1 || true
