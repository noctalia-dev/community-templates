# Spicetify: Noctalia colors for any theme

A Spicetify **extension** that applies your Noctalia colors (wallpaper or
palette) on top of **whatever theme is active**, including themes installed
through Marketplace. The theme keeps its layout and styling; only the colors
follow Noctalia. A "Noctalia colors" switch in Spotify turns it on and off.

## How it works

Every Spicetify theme takes its colors from `--spice-<key>` CSS variables.
`noctalia.js` sets those variables (the standard keys, plus extra keys used by
Text, Comfy and Colorful) to Noctalia's colors, with a higher priority than the
theme's own color scheme. Themes ignore keys they do not use.

On every Noctalia theme change:

1. Noctalia renders `noctalia.js` with the current colors into Spicetify's
   `Extensions` folder. Where that folder is differs between installs, so it
   is asked from Spicetify (`spicetify path userdata`) every time, not
   hard-coded.
2. `apply.sh` pushes it into Spotify:
   - **First time:** enables the extension in Spicetify
     (`spicetify config extensions noctalia.js`) and runs
     `spicetify apply --no-restart`, so playback is not interrupted. Restart
     Spotify once to load it.
   - **After that:** only `spicetify refresh -e`.
3. The running extension re-reads its file every 5 seconds and applies new
   colors without restarting Spotify. If that does not work in your Spotify
   build, the colors apply on the next Spotify start.

## Setup

Prerequisites: Spicetify installed and applied (`spicetify backup apply`), with
a theme active and `replace_colors = 1` (Marketplace themes need
`current_theme = marketplace`).

1. Enable the template. Nothing else to set up: the first theme change enables
   the extension in Spicetify.
2. Restart Spotify once.

If Noctalia's official **Spicetify** template is enabled, disable it: it
rewrites the Comfy/Colorful `color.ini` and runs `spicetify apply` as well.

### Manual installation (user template)

To use it without the community catalog, copy this folder somewhere, e.g.
`~/.config/noctalia/templates/spicetify-noctalia/`, and add to
`~/.config/noctalia/config.toml`. Use `$HOME`, not `~`, in the hooks: `~`
inside quotes is not expanded.

```toml
[theme.templates.user.spicetify-noctalia]
input_path  = "~/.config/noctalia/templates/spicetify-noctalia/noctalia.js"
output_path_dynamic = 'bash "$HOME/.config/noctalia/templates/spicetify-noctalia/apply.sh" output'
post_hook   = 'bash "$HOME/.config/noctalia/templates/spicetify-noctalia/apply.sh" apply'
hook_async  = false
```

Then run `noctalia msg templates-apply` to render it now.

## Using it

- Profile menu (top right) → **Noctalia colors**: on = Noctalia's colors over
  the current theme; off = the theme's own color scheme (pick it in
  Marketplace as usual). The choice is remembered.
- Switch themes in Marketplace freely; the colors follow along.

## Undo

Disabling the template runs `undo.sh`: it removes `noctalia.js` from
Spicetify's extension list (only if it is there), deletes the generated file
and its install marker, and runs `spicetify apply --no-restart`. Running it
again does nothing.

## When something is off

The hook fails with a message (shown in Noctalia's Settings, and in
`~/.cache/noctalia/noctalia.log`) instead of guessing:

| Situation | What happens |
| --- | --- |
| Spicetify not installed | Nothing is written; message |
| Spicetify's folder cannot be found | Nothing is written; message |
| Spotify updated or never patched (`spicetify` fails) | Spicetify's own error plus the fix: `spicetify backup apply` |
| You removed the extension from Spicetify by hand | It is **not** added back; the message says how to re-enable it, or disable the template |
| No theme active, or `replace_colors` off | Message: Spotify ignores theme colors in that case |

To turn Noctalia's colors off without uninstalling, use the in-app
**Noctalia colors** switch.

## Notes

- Hook side effects: on the first run, adds `noctalia.js` to Spicetify's
  `extensions` setting and runs `spicetify apply --no-restart`; later runs only
  `spicetify refresh -e`. Writes `noctalia.js` and an empty
  `.noctalia-installed` marker in Spicetify's `Extensions` folder. Downloads
  nothing.
- Containment: before writing or deleting, the hooks resolve symlinks and
  refuse to touch anything whose real path is outside Spicetify's folder (a
  symlinked dotfiles setup still works), and refuse to write through a file
  that is itself a symlink.
- Works with themes that take their colors from Spicetify's `--spice-*`
  variables, which is how Spicetify themes are meant to work. Themes that ship
  **external JavaScript** (theme JS) that sets colors itself, for example
  colors taken from the album art, or themes with hard-coded CSS colors, will
  partly or fully ignore Noctalia's colors. That is expected: the extension
  only controls Spicetify's color variables.
- A theme with its own unusual color key names will not pick those up; add the
  key to `noctalia.js`.
- Tested with Spicetify 2.46.4, Spotify 1.3.4.258 (Arch, `/opt/spotify`),
  Noctalia 5.4.0, Text from Marketplace and a base theme: colors applied, in-app switch and live updates work.
  Hooks tested against a stand-in `spicetify` for every case in the table
  above, plus a real first-run enable; dark and light renders checked.


