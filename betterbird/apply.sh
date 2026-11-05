#!/usr/bin/env bash
set -euo pipefail

# Wires the rendered Noctalia palette into every Betterbird profile:
#   - prepends @import "<css_file>"; to chrome/userChrome.css and chrome/userContent.css
#   - enables toolkit.legacyUserProfileCustomizations.stylesheets in user.js
# Both edits are idempotent. Anything that cannot be written is reported and
# skipped instead of aborting the run.

css_file="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/betterbird/noctalia.css"
import_line="@import \"$css_file\";"
pref_key='toolkit.legacyUserProfileCustomizations.stylesheets'
pref_line="user_pref(\"$pref_key\", true);"
marker="noctalia/betterbird/noctalia.css"

warn() { echo "betterbird: $*" >&2; }

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

if [ "${#roots[@]}" -eq 0 ]; then
    # Betterbird is not installed here, nothing to wire.
    exit 0
fi

# -L so profiles managed as symlinks are found too.
all_profiles=()
betterbird_profiles=()

while IFS= read -r -d '' prefs; do
    p="$(dirname "$prefs")"
    all_profiles+=("$p")
    # If the path itself is in a betterbird-named root, or compatibility.ini specifies betterbird
    if [[ "$p" =~ [Bb]etterbird ]] || ( [ -f "$p/compatibility.ini" ] && grep -qi "betterbird" "$p/compatibility.ini" ); then
        betterbird_profiles+=("$p")
    fi
done < <(find -L "${roots[@]}" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)

if [ "${#all_profiles[@]}" -eq 0 ]; then
    warn "no profile with prefs.js found under ${roots[*]}"
    exit 1
fi

if [ "${#betterbird_profiles[@]}" -gt 0 ]; then
    profiles=("${betterbird_profiles[@]}")
else
    profiles=("${all_profiles[@]}")
fi

for profile in "${profiles[@]}"; do
    chrome_dir="$profile/chrome"
    user_js="$profile/user.js"

    if [ ! -d "$chrome_dir" ] && ! mkdir -p "$chrome_dir" 2>/dev/null; then
        warn "$chrome_dir cannot be created, skipping profile"
        continue
    fi

    # userChrome.css and userContent.css: @import has to be the very first line.
    for target in "$chrome_dir/userChrome.css" "$chrome_dir/userContent.css"; do
        if [ ! -e "$target" ]; then
            if [ -w "$chrome_dir" ]; then
                printf '%s\n' "$import_line" >"$target"
            else
                warn "$target cannot be created, skipping import"
            fi
        elif grep -qF "$marker" "$target"; then
            touch "$target" # touch to invalidate Gecko stylesheet timestamp
        elif [ -w "$target" ]; then
            tmp="$(mktemp "${target}.tmp.XXXXXX")"
            printf '%s\n' "$import_line" >"$tmp"
            cat "$target" >>"$tmp"
            cat "$tmp" >"$target"
            rm -f "$tmp"
        else
            warn "$target is not writable, skipping import"
        fi
    done

    # Invalidate Gecko startup cache so CSS changes take effect immediately on next launch
    profile_name="$(basename "$profile")"
    rm -rf "$profile/startupCache" \
           "${XDG_CACHE_HOME:-$HOME/.cache}/thunderbird/$profile_name/startupCache" \
           "${XDG_CACHE_HOME:-$HOME/.cache}/betterbird/$profile_name/startupCache" \
           "$HOME/.cache/thunderbird/$profile_name/startupCache" \
           "$HOME/.cache/betterbird/$profile_name/startupCache" 2>/dev/null || true

    # user.js: keep the pref, never duplicate it, correct a stale false.
    if [ ! -e "$user_js" ]; then
        printf '%s\n' "$pref_line" >>"$user_js"
    elif ! grep -qF "$pref_key" "$user_js"; then
        if [ -w "$user_js" ]; then
            printf '%s\n' "$pref_line" >>"$user_js"
        else
            warn "$user_js is not writable, set $pref_key manually"
        fi
    elif grep -qE "$pref_key\",[[:space:]]*false" "$user_js"; then
        if [ -w "$user_js" ]; then
            tmp="$(mktemp "${user_js}.tmp.XXXXXX")"
            sed -E "s/($pref_key\",[[:space:]]*)false/\1true/" "$user_js" >"$tmp"
            cat "$tmp" >"$user_js"
            rm -f "$tmp"
        else
            warn "$user_js sets $pref_key to false and is not writable"
        fi
    fi
done
