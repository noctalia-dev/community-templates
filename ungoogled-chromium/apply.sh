#!/usr/bin/env bash
set -euo pipefail

theme_dir="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/ungoogled-chromium/theme"
note_file="$theme_dir/INSTALL.txt"

mkdir -p "$theme_dir"

# Chromium themes are just extensions: Noctalia renders manifest.json into
# $theme_dir on every palette change. The browser reads that folder as an
# unpacked theme, so the install path never changes and one manual load is
# enough. This hook only prints the one-time instructions the first time it
# runs (the note file doubles as the idempotency marker).
if [ ! -f "$note_file" ]; then
    cat >"$note_file" <<EOF
Noctalia theme for (ungoogled) Chromium — load it once:

  1. Open ungoogled-chromium and go to chrome://extensions
  2. Enable Developer mode (top-right toggle)
  3. Click "Load unpacked" and choose:
     $theme_dir

The theme stays installed: it points at this same folder, which Noctalia
rewrites on every palette change. Restart the browser after a theme or
palette update so the new colors are applied.
EOF
    echo "Noctalia ungoogled-chromium: load the theme once from chrome://extensions (details in $note_file)" >&2
fi
