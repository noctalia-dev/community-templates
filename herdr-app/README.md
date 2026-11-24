# Herdr App

Synchronizes [Herdr App](https://github.com/herdrdev/herdr-app)'s terminal background, foreground, selection, cursor, and 16 ANSI colors with Noctalia's terminal palette. The sidebar and tabs instead use Noctalia's UI color roles, including separate surfaces for the active tab and selected rows. This is for Herdr App, not the separate `herdr` TUI.

## Setup

1. Install Herdr App and enable **Herdr App** in Noctalia Settings → Templates.
2. In Herdr App's theme picker, select `noctalia` for each light and dark appearance you use. Theme choices are per layout, so repeat this for each layout you use.

Noctalia writes `$XDG_CONFIG_HOME/herdr-app/themes/noctalia.json` (normally `~/.config/herdr-app/themes/noctalia.json`). It overwrites that file whenever the template is rendered; back up any existing file at that path first. Herdr watches theme files and reloads changes while running. If needed, restart Herdr App after enabling the template.

The output path assumes the default Herdr App home. If `HERDR_APP_HOME` points elsewhere, this community template does not write there; use a Noctalia user template with an output path under `$HERDR_APP_HOME/themes/noctalia.json` instead (specify the actual path, as community template paths do not expand `HERDR_APP_HOME`).

Tested with Herdr App v0.1.16.
