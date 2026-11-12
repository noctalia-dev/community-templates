#!/usr/bin/env bash
set -euo pipefail

# Reverses the Noctalia palette wiring for every Betterbird profile:
#   - removes @import "<css_file>"; from chrome/userChrome.css and chrome/userContent.css
#   - removes toolkit.legacyUserProfileCustomizations.stylesheets from user.js
#   - clears Gecko startup cache so changes take effect immediately on next launch
#   - removes the rendered Noctalia palette file from cache
# This script is strictly idempotent and safe to run multiple times.

css_file="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/betterbird/noctalia.css"
marker="noctalia/betterbird/noctalia.css"
pref_key='toolkit.legacyUserProfileCustomizations.stylesheets'

roots=()
for root in \
    "${XDG_CONFIG_HOME:-$HOME/.config}/betterbird" \
    "$HOME/.betterbird" \
    "$HOME/.var/app/eu.betterbird.Betterbird/.betterbird" \
    "$HOME/.var/app/eu.betterbird.Betterbird/.thunderbird" \
    "$HOME/snap/betterbird/common/.betterbird" \
    "$HOME/snap/betterbird/common/.thunderbird" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/thunderbird" \
    "$HOME/.thunderbird" \
    "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" \
    "$HOME/snap/thunderbird/common/.thunderbird"; do
    [ -d "$root" ] && roots+=("$root")
done

if [ "${#roots[@]}" -gt 0 ]; then
    profiles=()
    while IFS= read -r -d '' prefs; do
        p="$(dirname "$prefs")"
        if [[ "$p" =~ [Bb]etterbird ]] || ( [ -f "$p/compatibility.ini" ] && grep -qi "betterbird" "$p/compatibility.ini" ); then
            profiles+=("$p")
        fi
    done < <(find -L "${roots[@]}" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)

    for profile in "${profiles[@]}"; do
        chrome_dir="$profile/chrome"
        user_js="$profile/user.js"

        # 1. Clean up userChrome.css and userContent.css
        for target in "$chrome_dir/userChrome.css" "$chrome_dir/userContent.css"; do
            if [ -f "$target" ] && grep -qF "$marker" "$target"; then
                if [ -w "$target" ]; then
                    tmp="$(mktemp "${target}.tmp.XXXXXX")"
                    grep -vF "$marker" "$target" >"$tmp" || true
                    if [ ! -s "$tmp" ] || ! grep -q '[^[:space:]]' "$tmp"; then
                        rm -f "$tmp" "$target"
                    else
                        cat "$tmp" >"$target"
                        rm -f "$tmp"
                    fi
                fi
            fi
        done

        # Remove empty chrome directory if we left it clean
        if [ -d "$chrome_dir" ]; then
            rmdir "$chrome_dir" 2>/dev/null || true
        fi

        # 2. Clean up toolkit.legacyUserProfileCustomizations.stylesheets in user.js
        if [ -f "$user_js" ] && grep -qF "$pref_key" "$user_js"; then
            if [ -w "$user_js" ]; then
                tmp="$(mktemp "${user_js}.tmp.XXXXXX")"
                grep -vF "$pref_key" "$user_js" >"$tmp" || true
                if [ ! -s "$tmp" ] || ! grep -q '[^[:space:]]' "$tmp"; then
                    rm -f "$tmp" "$user_js"
                else
                    cat "$tmp" >"$user_js"
                    rm -f "$tmp"
                fi
            fi
        fi

        # 3. Invalidate Gecko startup cache so changes take effect immediately
        profile_name="$(basename "$profile")"
        rm -rf "$profile/startupCache" \
               "${XDG_CACHE_HOME:-$HOME/.cache}/thunderbird/$profile_name/startupCache" \
               "${XDG_CACHE_HOME:-$HOME/.cache}/betterbird/$profile_name/startupCache" \
               "$HOME/.cache/thunderbird/$profile_name/startupCache" \
               "$HOME/.cache/betterbird/$profile_name/startupCache" 2>/dev/null || true
    done
fi

# 4. Remove cached rendered palette
rm -f "$css_file"
rmdir "${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/betterbird" 2>/dev/null || true
