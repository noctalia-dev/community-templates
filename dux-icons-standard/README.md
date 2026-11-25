# Dux Icons Standard

Recolors the Dux Icons theme so its tiles and glyphs follow the Noctalia palette. Whenever the Noctalia theme changes (wallpaper, palette, or dark/light mode), the icon theme is rebuilt in the new colors.

Uses the standard file and folder style, with background tiles.

> **Mutually exclusive with Dux Icons Color.** Both styles write the same palette file and rebuild the same theme (`$XDG_DATA_HOME/icons/dux-icons`). Enable only one; if both are enabled, the result depends on which hook runs last.

## What is themed

| Dux Icons option | Noctalia token |
| ---------------- | -------------- |
| `tile` | `colors.primary` |
| `glyph` | `colors.on_primary` |

The back plate uses the default Dux Icons color. App icons retain their original artwork and colors.

## Prerequisites

- `dux-icons` installed and available in `PATH`.
- The Dux Icons theme selected as your icon theme.

## Setup

Enable **Dux Icons Standard** in Noctalia under Settings → Templates, and keep Dux Icons Color disabled.
