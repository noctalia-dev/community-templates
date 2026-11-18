# rummage

Themes [rummage](https://github.com/barrulus/rummage), a native Wayland file manager, with the Noctalia palette.

## What is themed

The whole window: sidebar, file views, toolbar, menus, dialogs, selections and the menu highlight. rummage maps the
Material roles itself, so the template only writes data.

## Prerequisites

rummage with palette file support (tested with 0.6.0).

## Setup

None. Enable the template in Settings -> Templates and apply a theme (re-applying the current one is enough).

## Output

`$XDG_CONFIG_HOME/rummage/colors.toml` (normally `~/.config/rummage/colors.toml`).

rummage watches this file and reloads it live; no restart is needed. A valid `colors.toml` takes precedence over the
desktop's portal colours, as long as **Settings -> Appearance** in rummage is set to *Desktop/Noctalia*
(`appearance.color_scheme = "system"`, the default). Choosing light or dark there instead derives a palette from the
accent only.

## Notes

- No hooks: nothing in rummage's own `config.toml` is touched.
- The file is overwritten on every theme change; do not edit it by hand.
- Disabling the template leaves the last `colors.toml` in place. Delete it to return to the desktop or built-in colours.
