#!/usr/bin/env bash
set -euo pipefail

schema=org.freedesktop.ibus.panel
theme=noctalia-ibus

if ! command -v gsettings >/dev/null 2>&1; then
  echo "noctalia-ibus: gsettings not found" >&2
  exit 1
fi
if ! gsettings list-keys "$schema" >/dev/null 2>&1; then
  echo "noctalia-ibus: GSettings schema $schema not found; is ibus installed?" >&2
  exit 1
fi

gsettings set "$schema" custom-theme "$theme"

# GTK 3 re-reads a theme only when its name is set, and ibus sets it only when
# one of these keys changes, so switch the custom theme off and on again.
gsettings set "$schema" use-custom-theme false
gsettings set "$schema" use-custom-theme true
