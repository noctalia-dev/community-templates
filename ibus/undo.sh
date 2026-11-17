#!/usr/bin/env bash
set -euo pipefail

schema=org.freedesktop.ibus.panel
theme=noctalia-ibus
theme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/themes/$theme"

# If a user has a custom theme other than noctalia-ibus, leave it as is.
if command -v gsettings >/dev/null 2>&1 &&
  gsettings list-keys "$schema" >/dev/null 2>&1 &&
  [ "$(gsettings get "$schema" custom-theme)" = "'$theme'" ]; then
  gsettings reset "$schema" use-custom-theme
  gsettings reset "$schema" custom-theme
fi

rm -f -- "$theme_dir/gtk-3.0/gtk.css"
rmdir -- "$theme_dir/gtk-3.0" "$theme_dir" 2>/dev/null || true
