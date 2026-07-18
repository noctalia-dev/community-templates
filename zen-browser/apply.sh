#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
css_chrome="$cache_dir/noctalia/zen-browser/zen-userChrome.css"
css_content="$cache_dir/noctalia/zen-browser/zen-userContent.css"
line_chrome="@import \"$css_chrome\";"
line_content="@import \"$css_content\";"

find "${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen" -mindepth 2 -maxdepth 2 -type f -name "prefs.js" -print0 2>/dev/null |
    while IFS= read -r -d '' prefs_file; do
        profile_dir=$(dirname "$prefs_file")
        chrome_dir="$profile_dir/chrome"
        user_chrome="$chrome_dir/userChrome.css"
        user_content="$chrome_dir/userContent.css"
        user_js="$profile_dir/user.js"

        mkdir -p "$chrome_dir"
        touch "$user_chrome" "$user_content" "$user_js"

        sed -i '/zen-browser\/zen-userChrome\.css/d' "$user_chrome"
        sed -i '/zen-browser\/zen-userContent\.css/d' "$user_content"

        if ! grep -Fq "$line_chrome" "$user_chrome"; then
            [ -s "$user_chrome" ] && [ -n "$(tail -c1 "$user_chrome")" ] && echo >>"$user_chrome"
            printf '%s\n' "$line_chrome" >>"$user_chrome"
        fi

        if ! grep -Fq "$line_content" "$user_content"; then
            [ -s "$user_content" ] && [ -n "$(tail -c1 "$user_content")" ] && echo >>"$user_content"
            printf '%s\n' "$line_content" >>"$user_content"
        fi

        sed -i '/toolkit\.legacyUserProfileCustomizations\.stylesheets/d' "$user_js"
        sed -i '/devtools\.chrome\.enabled/d' "$user_js"
        printf '%s\n' \
            'user_pref("devtools.chrome.enabled", true);' \
            'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >>"$user_js"
    done
