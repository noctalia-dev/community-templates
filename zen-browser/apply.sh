#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
css_chrome="$cache_dir/noctalia/zen-browser/zen-userChrome.css"
css_content="$cache_dir/noctalia/zen-browser/zen-userContent.css"
line_chrome="@import \"$css_chrome\";"
line_content="@import \"$css_content\";"

write_if_changed() {
    local target="$1" tmp="$2"
    if ! cmp -s "$target" "$tmp"; then
        cat "$tmp" >"$target"
    fi
    rm -f "$tmp"
}

find "${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen" -mindepth 2 -maxdepth 2 -type f -name "prefs.js" -print0 2>/dev/null |
    while IFS= read -r -d '' prefs_file; do
        profile_dir=$(dirname "$prefs_file")
        chrome_dir="$profile_dir/chrome"
        user_chrome="$chrome_dir/userChrome.css"
        user_content="$chrome_dir/userContent.css"
        user_js="$profile_dir/user.js"

        mkdir -p "$chrome_dir"
        touch "$user_chrome" "$user_content" "$user_js"

        tmp_chrome="$(mktemp "${user_chrome}.tmp.XXXXXX")"
        sed '/zen-browser\/zen-userChrome\.css/d' "$user_chrome" >"$tmp_chrome"
        if ! grep -Fq "$line_chrome" "$tmp_chrome"; then
            [ -s "$tmp_chrome" ] && [ -n "$(tail -c1 "$tmp_chrome")" ] && echo >>"$tmp_chrome"
            printf '%s\n' "$line_chrome" >>"$tmp_chrome"
        fi
        write_if_changed "$user_chrome" "$tmp_chrome"

        tmp_content="$(mktemp "${user_content}.tmp.XXXXXX")"
        sed '/zen-browser\/zen-userContent\.css/d' "$user_content" >"$tmp_content"
        if ! grep -Fq "$line_content" "$tmp_content"; then
            [ -s "$tmp_content" ] && [ -n "$(tail -c1 "$tmp_content")" ] && echo >>"$tmp_content"
            printf '%s\n' "$line_content" >>"$tmp_content"
        fi
        write_if_changed "$user_content" "$tmp_content"

        tmp_js="$(mktemp "${user_js}.tmp.XXXXXX")"
        sed \
            -e '/toolkit\.legacyUserProfileCustomizations\.stylesheets/d' \
            -e '/devtools\.chrome\.enabled/d' \
            "$user_js" >"$tmp_js"
        [ -s "$tmp_js" ] && [ -n "$(tail -c1 "$tmp_js")" ] && echo >>"$tmp_js"
        printf '%s\n' \
            'user_pref("devtools.chrome.enabled", true);' \
            'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >>"$tmp_js"
        write_if_changed "$user_js" "$tmp_js"
    done
