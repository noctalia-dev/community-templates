#!/usr/bin/env bash
# Runs on every theme change (post_hook). Converts the rendered Theme_Colors.xcu's
# hex color values to the decimal integers LibreOffice's ColorScheme schema
# actually requires, assembles a fresh .oxt from this directory's static files
# plus the converted colors, and installs it via unopkg.
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDERED="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/libreoffice-theme-staging/Theme_Colors.xcu"
BUILD_DIR="$CONFIG_DIR/build"
OXT_PATH="$BUILD_DIR/noctalia-theme.oxt"

if [ ! -f "$RENDERED" ]; then
  echo "noctalia libreoffice: rendered Theme_Colors.xcu not found at $RENDERED" >&2
  exit 1
fi

rm -rf "$BUILD_DIR/pkg"
mkdir -p "$BUILD_DIR/pkg/META-INF"

# Convert every 6-hex-digit <value>...</value> to its decimal equivalent.
# ColorScheme's schema stores colors as base-10 integers, not hex strings.
python3 - "$RENDERED" "$BUILD_DIR/pkg/Theme_Colors.xcu" << 'PYEOF'
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    content = f.read()


def hex_to_dec(match):
    return f"<value>{int(match.group(1), 16)}</value>"


converted = re.sub(r"<value>([0-9a-fA-F]{6})</value>", hex_to_dec, content)
with open(dst, "w") as f:
    f.write(converted)
PYEOF

cp "$CONFIG_DIR/Paths.xcu" "$BUILD_DIR/pkg/Paths.xcu"
cp "$CONFIG_DIR/description.xml" "$BUILD_DIR/pkg/description.xml"
cp "$CONFIG_DIR/pkg-description.en" "$BUILD_DIR/pkg/pkg-description.en"
cp "$CONFIG_DIR/META-INF/manifest.xml" "$BUILD_DIR/pkg/META-INF/manifest.xml"

rm -f "$OXT_PATH"
(cd "$BUILD_DIR/pkg" && zip -qr "$OXT_PATH" .)

# unopkg add --force while LibreOffice is running has been confirmed live to
# silently corrupt the install (it can remove the old registration before
# failing to add the new one, leaving nothing installed at all). Skip the
# install step entirely rather than risk that -- the .oxt is still rebuilt
# above so the next run (once LibreOffice is closed) installs the current
# colors, and a restart is already required to see any change regardless.
if pgrep -x soffice.bin >/dev/null 2>&1; then
  echo "noctalia libreoffice: LibreOffice is running, skipping extension install this run (it would corrupt the existing install). Close LibreOffice and re-apply the theme, or just restart it once, to pick up the new colors." >&2
  exit 0
fi

EXT_ID="dev.noctalia.libreoffice.theme"
UNOPKG="$(command -v unopkg || true)"
if [ -z "$UNOPKG" ]; then
  UNOPKG_CMD=(flatpak run --command=/app/libreoffice/program/unopkg org.libreoffice.LibreOffice)
else
  UNOPKG_CMD=("$UNOPKG")
fi

# `add --force` alone has been confirmed live to leave the extension in a
# broken state (a stale cache index pointing at a deleted temp dir, `list`
# then reports nothing installed at all, and every later reinstall fails
# with "file opening ... NOT_EXISTING" until the cache is cleared by hand).
# Explicitly removing the old registration first, ignoring failure since it
# may not be installed yet, avoids relying on --force to do that atomically.
"${UNOPKG_CMD[@]}" remove "$EXT_ID" >/dev/null 2>&1 || true
"${UNOPKG_CMD[@]}" add --force "$OXT_PATH" 2>&1 \
  || echo "noctalia libreoffice: unopkg install failed" >&2
