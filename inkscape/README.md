# Inkscape (WORK IN PROGRESS, not ready for PR yet)

Inkscape ships its own personal-override CSS hook, `ui/user.css`, empty by default and imported
automatically ("This is a CSS override that users can provide to override Inkscape's and theme
styles"). No extra setup needed once this file is in place.

## Why this isn't a simple `@define-color` swap like GIMP

Inkscape's default active theme, `Minwaita-Inkscape` (its own bundled GTK3 theme fork, not the
system's real Adwaita), hardcodes literal hex colors throughout instead of routing through shared
`@define-color` roles: confirmed 763 literal hex values vs only 35 named-color uses across its
~6800-line `gtk-3.0/gtk.css`/`gtk-dark.css`. Redefining GTK's standard `theme_*` names alone (the
approach that fully worked for GIMP) only covers the narrow parts of the UI that actually reference
those names — the bulk of the visible chrome does not.

`user.css` does load at a higher GTK style-provider priority than the active theme (confirmed
against Inkscape's own `src/ui/themes.cpp` source), so it reliably wins wherever it directly
targets a selector — the fix is identifying the *right* selectors, not fighting priority.

## Selectors used, and how each was confirmed (not guessed)

Every selector below was found by cross-referencing Inkscape's real source
(gitlab.com/inkscape/inkscape) for exact widget names/IDs, then confirmed live with a targeted
solid-color CSS probe and a screenshot — never assumed from the theme file alone.

- `menubar`, `scrolledwindow`, `.background` — root window chrome.
- `notebook header` / `notebook header tabs tab:checked` — docked panel (Layers, Fill & Stroke,
  etc.) tab strip. Checked state uses a bottom `box-shadow` accent bar on a dark background,
  matching the noctalia-dev/community-templates#58 GIMP template's pattern, not a full fill.
- `#NotebookPage` — docked panel body content.
- `button.square-button` (+ `:hover`, `:checked`, `:checked image`) — the vertical toolbox's tool
  icons. Confirmed via `share/ui/toolbar-tool.ui`: each tool is a `GtkRadioButton.square-button`
  inside a `GtkFlowBox` inside a `GtkScrolledWindow`. This one **does** use a full accent fill with
  a dark icon/text override (kept deliberately, matches GIMP's own toolbox treatment) rather than
  the box-shadow style used elsewhere.
- `#SelectToolbar`, `#NodeToolbar`, ... (one ID per tool) — the horizontal tool-options bar.
  Confirmed via `src/ui/toolbar/toolbars.cpp`: each tool's toolbar widget gets
  `set_name(toolName + "Toolbar")`. Every tool from `toolbars.cpp`'s own registry is listed.
- `entry` / `entry:focus` — number/text entry fields (X, Y, W, H, etc.).
- `#DesktopStatusBar` — the bottom status bar.

## Known gap

`#3DBoxToolbar` is deliberately left out: CSS identifiers starting with a digit are invalid
(`#3DBoxToolbar` would need an escape like `#\33 DBoxToolbar`), not yet tried. The 3D Box tool's
options bar stays unthemed until this is resolved.

## Requires Inkscape's own "Minwaita-Inkscape" base theme

Preferences > Interface > Theming > "Change GTK theme" must stay on the default
`Minwaita-Inkscape` (do **not** pick "Adwaita" from that dropdown — it does not correspond to a
real loadable theme folder for Inkscape and silently falls back to GTK's compiled-in default,
which ignores most of this override; confirmed by direct testing, this looked like "nothing themed
at all" until root-caused).

## Native install

`user.css` lives at `~/.config/inkscape/ui/user.css`.

## Flatpak install (`org.inkscape.Inkscape`)

Same file, inside the sandbox's own isolated config:
`~/.var/app/org.inkscape.Inkscape/config/inkscape/ui/user.css`. No `flatpak override` needed.

## Status

Verified live against Inkscape 1.4.4 (Flatpak) with no CSS parse errors: menu bar, toolbox
(full accent fill + dark icon on the active tool), tool-options bar entries, docked panel tabs
(box-shadow accent) and body, status bar. Not yet verified: Preferences dialog, right-click context
menus, the 3D Box tool gap above. Not yet opened as a PR — still being refined.
