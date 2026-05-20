#!/usr/bin/env bash
set -euo pipefail

css_chrome="$HOME/.cache/noctalia/zen-browser/zen-userChrome.css"
css_content="$HOME/.cache/noctalia/zen-browser/zen-userContent.css"
line_chrome="@import \"$css_chrome\";"
line_content="@import \"$css_content\";"

find "$HOME/.config/zen" "$HOME/.zen" "$HOME/.var/app/app.zen_browser.zen/.zen" -mindepth 2 -maxdepth 2 -type d -name chrome -print0 2>/dev/null |
    while IFS= read -r -d '' dir; do
        user_chrome="$dir/userChrome.css"
        user_content="$dir/userContent.css"
        mkdir -p "$dir"
        touch "$user_chrome" "$user_content"
        sed -i '/zen-browser\/zen-userChrome\.css/d' "$user_chrome"
        sed -i '/zen-browser\/zen-userContent\.css/d' "$user_content"
        if ! grep -Fq "$line_chrome" "$user_chrome"; then
            printf '%s\n' "$line_chrome" >>"$user_chrome"
        fi
        if ! grep -Fq "$line_content" "$user_content"; then
            printf '%s\n' "$line_content" >>"$user_content"
        fi
    done
