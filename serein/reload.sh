#!/usr/bin/env bash
set -euo pipefail

output="${XDG_DATA_HOME:-$HOME/.local/share}/serein/noctalia.serein-extension"
installed_dir="${XDG_DATA_HOME:-$HOME/.local/share}/serein/extensions/themes/noctalia"
installed="$installed_dir/package.json"

command -v jq >/dev/null || {
    printf 'reload.sh: jq is required\n' >&2
    exit 1
}

[[ -s "$output" ]] || {
    printf 'reload.sh: generated theme is missing: %s\n' "$output" >&2
    exit 1
}

mkdir -p "$installed_dir"

sha256="$(sha256sum "$output" | cut -d' ' -f1)"
bytes="$(stat -c '%s' "$output")"
tmp="$(mktemp "${installed}.tmp.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

jq -cn \
    --argjson package "$(<"$output")" \
    --arg sha256 "$sha256" \
    --argjson bytes "$bytes" \
    '{local_theme:false, package:$package, grants:[], reviewed:false, sha256:$sha256, download_bytes:$bytes}' \
    > "$tmp"

if cmp -s "$tmp" "$installed"; then
    exit 0
fi

install -m 0644 "$tmp" "$installed"

# Serein has no theme reload IPC. The user can restart Serein to load the
# updated package; this hook never closes or launches the application.
