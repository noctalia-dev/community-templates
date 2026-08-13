#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
css_chrome="$cache_dir/noctalia/librewolf/librewolf-userChrome.css"
css_content="$cache_dir/noctalia/librewolf/librewolf-userContent.css"
line_chrome="@import \"$css_chrome\";"
line_content="@import \"$css_content\";"

write_if_changed() {
    local target="$1" tmp="$2"
    if ! cmp -s "$target" "$tmp"; then
        cat "$tmp" >"$target"
    fi
    rm -f "$tmp"
}

# LibreWolf keeps one prefs.js per profile, under one of these roots:
#   ~/.librewolf                                   (regular installs)
#   $XDG_CONFIG_HOME/librewolf                     (new XDG layout; profiles may
#                                                   sit directly under it or one
#                                                   level deeper under librewolf/)
#   ~/.var/app/io.gitlab.librewolf-community/...   (Flatpak)
#   ~/snap/librewolf/common/...                    (Snap)
roots=()
for root in \
    "${HOME}/.librewolf" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/librewolf" \
    "${HOME}/.var/app/io.gitlab.librewolf-community/.librewolf" \
    "${HOME}/snap/librewolf/common/.librewolf"
do
    [ -d "$root" ] && roots+=("$root")
done

if [ "${#roots[@]}" -gt 0 ]; then
    find "${roots[@]}" -mindepth 1 -maxdepth 3 -type f -name "prefs.js" -print0 2>/dev/null |
        while IFS= read -r -d '' prefs_file; do
            profile_dir=$(dirname "$prefs_file")
            chrome_dir="$profile_dir/chrome"
            user_chrome="$chrome_dir/userChrome.css"
            user_content="$chrome_dir/userContent.css"
            user_js="$profile_dir/user.js"

            mkdir -p "$chrome_dir"
            touch "$user_chrome" "$user_content" "$user_js"

            tmp_chrome="$(mktemp "${user_chrome}.tmp.XXXXXX")"
            sed '/noctalia\/librewolf\/librewolf-userChrome\.css/d' "$user_chrome" >"$tmp_chrome"
            if ! grep -Fq "$line_chrome" "$tmp_chrome"; then
                [ -s "$tmp_chrome" ] && [ -n "$(tail -c1 "$tmp_chrome")" ] && echo >>"$tmp_chrome"
                printf '%s\n' "$line_chrome" >>"$tmp_chrome"
            fi
            write_if_changed "$user_chrome" "$tmp_chrome"

            tmp_content="$(mktemp "${user_content}.tmp.XXXXXX")"
            sed '/noctalia\/librewolf\/librewolf-userContent\.css/d' "$user_content" >"$tmp_content"
            if ! grep -Fq "$line_content" "$tmp_content"; then
                [ -s "$tmp_content" ] && [ -n "$(tail -c1 "$tmp_content")" ] && echo >>"$tmp_content"
                printf '%s\n' "$line_content" >>"$tmp_content"
            fi
            write_if_changed "$user_content" "$tmp_content"

            tmp_js="$(mktemp "${user_js}.tmp.XXXXXX")"
            sed \
                -e '/toolkit\.legacyUserProfileCustomizations\.stylesheets/d' \
                -e '/svg\.context-properties\.content\.enabled/d' \
                -e '/devtools\.chrome\.enabled/d' \
                "$user_js" >"$tmp_js"
            [ -s "$tmp_js" ] && [ -n "$(tail -c1 "$tmp_js")" ] && echo >>"$tmp_js"
            printf '%s\n' \
                'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
                'user_pref("svg.context-properties.content.enabled", true);' \
                'user_pref("devtools.chrome.enabled", true);' >>"$tmp_js"
            write_if_changed "$user_js" "$tmp_js"
        done
fi
