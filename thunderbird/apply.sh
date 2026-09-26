#!/usr/bin/env bash
set -euo pipefail

# Wires the rendered Noctalia palette into every Thunderbird profile:
#   - prepends @import "<css_file>"; to chrome/userChrome.css
#   - enables toolkit.legacyUserProfileCustomizations.stylesheets in user.js
# Both edits are idempotent and skipped when the target file is not writable
# (Nix / Home Manager profiles are read-only symlinks).

css_file="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/thunderbird/noctalia.css"
import_line="@import \"$css_file\";"
pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
marker="noctalia/thunderbird/noctalia.css"

roots=()
for root in \
    "$HOME/.thunderbird" \
    "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" \
    "$HOME/snap/thunderbird/common/.thunderbird"; do
    [ -d "$root" ] && roots+=("$root")
done

if [ "${#roots[@]}" -eq 0 ]; then
    # Thunderbird is not installed here, nothing to wire.
    exit 0
fi

profiles=()
while IFS= read -r -d '' prefs; do
    profiles+=("$(dirname "$prefs")")
done < <(find "${roots[@]}" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)

if [ "${#profiles[@]}" -eq 0 ]; then
    echo "thunderbird: no profile with prefs.js found under ${roots[*]}" >&2
    exit 1
fi

for profile in "${profiles[@]}"; do
    chrome_dir="$profile/chrome"
    user_chrome="$chrome_dir/userChrome.css"
    user_js="$profile/user.js"
    mkdir -p "$chrome_dir"

    # userChrome.css: @import has to be the very first line.
    if [ ! -e "$user_chrome" ]; then
        printf '%s\n' "$import_line" >"$user_chrome"
    elif grep -qF "$marker" "$user_chrome"; then
        : # already wired
    elif [ -w "$user_chrome" ]; then
        tmp="$(mktemp "${user_chrome}.tmp.XXXXXX")"
        printf '%s\n' "$import_line" >"$tmp"
        cat "$user_chrome" >>"$tmp"
        cat "$tmp" >"$user_chrome"
        rm -f "$tmp"
    else
        echo "thunderbird: $user_chrome is not writable, skipping import" >&2
    fi

    # user.js: keep the pref, never duplicate it.
    if [ -e "$user_js" ] && grep -qF 'toolkit.legacyUserProfileCustomizations.stylesheets' "$user_js"; then
        : # pref already set
    elif [ ! -e "$user_js" ] || [ -w "$user_js" ]; then
        printf '%s\n' "$pref_line" >>"$user_js"
    else
        echo "thunderbird: $user_js is not writable, set toolkit.legacyUserProfileCustomizations.stylesheets manually" >&2
    fi
done
