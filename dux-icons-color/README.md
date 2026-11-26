# Dux Icons Color

Recolors the Dux Icons theme so its tiles and glyphs follow the Noctalia palette. Whenever the Noctalia theme changes (wallpaper, palette, or dark/light mode), the icon theme is rebuilt in the new colors.

Uses background-free, category-colored file and folder icons.

> **Mutually exclusive with Dux Icons Standard.** Both styles write the same palette file and rebuild the same theme (`$XDG_DATA_HOME/icons/dux-icons`). Enable only one; if both are enabled, the result depends on which hook runs last.

## What is themed

| Dux Icons option | Noctalia token |
| ---------------- | -------------- |
| `tile` | `colors.primary` |
| `glyph` | `colors.on_primary` |

File and folder icons use the Dux Icons color style. App icons retain their original artwork and colors.

## Prerequisites

- `dux-icons` installed and available in `PATH`.
- The Dux Icons theme selected as your icon theme.

## Setup

Enable **Dux Icons Color** in Noctalia under Settings → Templates, and keep Dux Icons Standard disabled.
