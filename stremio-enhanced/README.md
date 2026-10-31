# Stremio Enhanced

Themes [Stremio Enhanced](https://github.com/REVENGE977/stremio-enhanced) with
your Noctalia colors (wallpaper or palette), plus an optional plugin that
reloads the theme live when the colors change.

## What is themed

The theme sets Stremio's own color variables (backgrounds, modals,
foreground text, accents, overlays, warning and danger colors) and nothing
else, so Stremio keeps its own look: outline icons, the active page in the
accent color. It follows Noctalia's current mode (dark or light).

## Generated files

| File | Path |
| --- | --- |
| Theme | `~/.config/stremio-enhanced/themes/noctalia.theme.css` |
| Live reload plugin | `~/.config/stremio-enhanced/plugins/noctalia-live-sync.plugin.js` |

Stremio Enhanced always reads these two folders under `~/.config`, even when
`XDG_CONFIG_HOME` is set, so the paths are fixed to match. Both entries are
skipped when `~/.config/stremio-enhanced` does not exist (Stremio Enhanced not
installed or never started).

## Setup

1. Install Stremio Enhanced and start it once (it creates its folders).
2. Enable this template in Noctalia's settings.
3. In Stremio Enhanced: **Settings**, scroll down, **Apply** the **Noctalia**
   theme. It may only appear after restarting Stremio Enhanced.
4. Optional, for live updates: in the same place, enable the
   **Noctalia Live Sync** plugin, then press <kbd>Ctrl</kbd>+<kbd>R</kbd> or
   restart.

Without the plugin, new colors apply the next time Stremio Enhanced starts
(or on <kbd>Ctrl</kbd>+<kbd>R</kbd>).

## How it works

Noctalia rewrites `noctalia.theme.css` on every theme change. Stremio Enhanced
loads the active theme as a stylesheet link (`<link id="activeTheme">`). The
plugin checks that file every 2 seconds while the Noctalia theme is active and
reloads the link when the content changed. It does nothing when another theme
is applied, and makes no network requests (it only reads the local theme file
Stremio Enhanced already loads).

## Notes

- No hooks: the template only writes the two files above. Choosing the theme
  and enabling the plugin stay in Stremio Enhanced's settings.
- Disabling the template leaves the two files in place. To remove them, apply
  another theme in Stremio Enhanced, disable the plugin, then delete the files.
- Parts of Stremio that do not use its color variables keep their own
  colors; with a light palette, check that everything stays readable.
- Tested with Stremio Enhanced 1.2.0 (Arch, `stremio-enhanced-bin`) and
  Noctalia 5.4.0, dark and light renders.
