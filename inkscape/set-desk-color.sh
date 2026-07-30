#!/usr/bin/env bash
# Sets Inkscape's canvas "desk" (pasteboard) color to match the active
# Noctalia theme. This is a real user preference stored as an XML
# attribute in preferences.xml, not something reachable via user.css --
# Inkscape's canvas is a custom-drawn widget, not plain GTK chrome.
set -euo pipefail

DESK_COLOR="{{colors.surface.default.hex}}"

for prefs in \
  "$HOME/.config/inkscape/preferences.xml" \
  "$HOME/.var/app/org.inkscape.Inkscape/config/inkscape/preferences.xml"
do
  if [ -f "$prefs" ]; then
    sed -i "s/deskcolor=\"#[0-9a-fA-F]\{6,8\}\"/deskcolor=\"$DESK_COLOR\"/" "$prefs"
  fi
done
