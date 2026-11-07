#!/usr/bin/env bash
set -euo pipefail

installed_dir="${XDG_DATA_HOME:-$HOME/.local/share}/serein/extensions/themes/noctalia"
installed="$installed_dir/package.json"
themes_dir="${XDG_DATA_HOME:-$HOME/.local/share}/serein/extensions/themes"

if [[ "${1:-}" == "prepare" ]]; then
    mkdir -p -- "$installed_dir" "$themes_dir"
    exit 0
fi

command -v jq >/dev/null || {
    printf 'reload.sh: jq is required\n' >&2
    exit 1
}

[[ -s "$installed" ]] || {
    printf 'reload.sh: generated theme package is missing: %s\n' "$installed" >&2
    exit 1
}

package_tmp="$(mktemp "${installed}.payload.XXXXXX")"
wrapper_tmp="$(mktemp "${installed}.tmp.XXXXXX")"
trap 'rm -f "$package_tmp" "$wrapper_tmp"' EXIT

if jq -e '.package | objects' "$installed" >/dev/null 2>&1; then
    jq -cS '.package' "$installed" > "$package_tmp"
else
    jq -cS . "$installed" > "$package_tmp"
fi

jq -e '(.manifest.id == "noctalia") and (.theme | type == "object")' \
    "$package_tmp" >/dev/null || {
    printf 'reload.sh: rendered file is not a valid Noctalia Serein theme package: %s\n' "$installed" >&2
    exit 1
}

sha256="$(sha256sum "$package_tmp" | cut -d' ' -f1)"
bytes="$(stat -c '%s' "$package_tmp")"

jq -cn \
    --argjson package "$(<"$package_tmp")" \
    --arg sha256 "$sha256" \
    --argjson bytes "$bytes" \
    '{local_theme:false, package:$package, grants:[], reviewed:false, sha256:$sha256, download_bytes:$bytes}' \
    > "$wrapper_tmp"

if ! cmp -s "$wrapper_tmp" "$installed"; then
    chmod 0644 "$wrapper_tmp"
    mv -f -- "$wrapper_tmp" "$installed"
fi

