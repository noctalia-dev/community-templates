# Serein

Synchronizes Serein's native theme package with the active Noctalia palette.

## Requirements

- Noctalia v5 or newer with community templates enabled.
- Serein with support for version 1 theme packages.

## Setup

1. Open Noctalia Settings → Templates.
2. Enable **serein**.
3. Noctalia writes the generated package to:

   ```text
   $XDG_DATA_HOME/serein-theme/noctalia.serein-extension
   ```

   When `XDG_DATA_HOME` is unset, this resolves to
   `~/.local/share/serein-theme/noctalia.serein-extension`.

4. In Serein, open **Settings → Themes → Import** and select the generated
   `.serein-extension` file.

The generated package contains both dark and light palettes. The active
Noctalia appearance determines which input file is rendered.

## Updating

Noctalia regenerates the output whenever its palette or appearance changes.
Serein does not watch external theme files, so import the generated package
again in Serein after a palette change. If the theme is already installed,
replace or re-import the existing `Noctalia` theme.

This template has no hooks and downloads nothing. It only writes the generated
Serein theme package to the output path above.

## What is themed

The template maps Noctalia surface, text, container, accent, semantic and
mention colors to Serein's theme API. It also disables transparency and blur
and supplies the shared control style used by both appearances.

Tested with Serein `1.0.0-nightly.20261103.74` and Noctalia `5.4.1`.
