# Ungoogled Chromium

Themes the (ungoogled) Chromium browser chrome with the Noctalia palette.

Chromium has no `userChrome.css` equivalent, so this template uses Chromium's
native theming mechanism: a **theme extension** (a folder with a `manifest.json`
that declares colors and tints). Noctalia renders that manifest with the current
palette into a stable location; you load it into the browser **once**, and every
palette/theme change after that only rewrites the manifest in place.

## What it themes

Chromium theme colors apply to the window frame, tab strip / toolbar, the
bookmark bar text, and the new-tab page. The template maps the Noctalia M3
tokens onto those colors:

| Chromium key | Noctalia token |
| --- | --- |
| `frame` / `frame_inactive` | `background` / `surface_dim` |
| `toolbar` | `surface_container` |
| `tab_text` / `bookmark_text` | `on_surface` |
| `tab_background_text` | `on_surface_variant` |
| `ntp_background` | `surface_container_low` |
| `ntp_text` | `on_surface` |
| `ntp_link` | `primary` |
| `button_background` | `surface_container_high` |
| `control_background` | `surface_container` |

Because a static theme cannot follow `prefers-color-scheme`, the manifest uses
`default`-mode tokens (your current Noctalia mode). Switching dark/light in
Noctalia re-renders the manifest; restart the browser to apply.

## Setup

1. **Apply the template** in Noctalia (Settings → Templates, or `noctalia msg
   templates-apply`). It writes:
   `$XDG_CACHE_HOME/noctalia/ungoogled-chromium/theme/manifest.json`
2. **Load it once** in the browser:
   - Open `chrome://extensions`
   - Enable **Developer mode** (top-right)
   - Click **Load unpacked** and choose
     `$XDG_CACHE_HOME/noctalia/ungoogled-chromium/theme`
3. (Alternative) launch with `--load-extension=$XDG_CACHE_HOME/noctalia/ungoogled-chromium/theme`
   — useful for wrapper scripts / portable setups.

The unpacked theme stays installed (Chromium remembers the path), and it points
at the folder Noctalia rewrites, so future palette changes just need a browser
restart.

## Apply changes

Restart the browser after a palette/theme update so the new colors are applied.

## Troubleshooting

- **Theme not appearing:** confirm the folder was loaded as an unpacked
  extension (`chrome://extensions` shows "Noctalia" under Themes), and that the
  path you loaded is exactly the path above — if you copied the theme elsewhere,
  updates stop.
- **Only part of the UI changes:** Chromium theme colors cover the frame, tabs,
  toolbar, bookmark text and the new-tab page; in-page content keeps its own
  colors (use the Noctalia GTK templates for the wider desktop).

## Removing the theme

In `chrome://extensions`, remove (trash icon) the "Noctalia" theme, then disable
the template in Noctalia.

## Files

| File | Purpose |
| --- | --- |
| `template.toml` | Noctalia manifest (renders the theme, runs `apply.sh`) |
| `manifest.json` | Chromium theme manifest with Noctalia colors/tints |
| `apply.sh` | Idempotent hook: prints one-time install instructions |

> Note: the `pywalfox` / `pywalfox-beta4` community templates theme *Firefox*
> via an extension; this template is the Chromium equivalent of the CSS-based
> `firefox/` and `zen-browser/` templates.
