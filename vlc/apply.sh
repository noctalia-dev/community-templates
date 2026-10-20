#!/usr/bin/env bash
set -euo pipefail

# The palette itself comes from the built-in Qt template; this template only makes VLC 3 (Qt5) use it.
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

if [ ! -f "$config_home/qt5ct/colors/noctalia.conf" ]; then
    echo "Error: $config_home/qt5ct/colors/noctalia.conf not found; enable the built-in Qt template so VLC has a palette" >&2
    exit 1
fi

if ! command -v qt5ct >/dev/null 2>&1; then
    echo "Warning: qt5ct is not installed; VLC 3 needs it to use the Noctalia palette" >&2
fi

# VLC's own "dark palette" option replaces the qt5ct palette with a fixed gray and blue one.
vlcrc="$config_home/vlc/vlcrc"
if [ -f "$vlcrc" ] && grep -q '^qt-dark-palette=1' "$vlcrc"; then
    sed -i 's/^qt-dark-palette=1/qt-dark-palette=0/' "$vlcrc"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$data_home/applications" || true
fi
