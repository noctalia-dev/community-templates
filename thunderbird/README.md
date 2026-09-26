# Thunderbird

Keeps [Thunderbird](https://www.thunderbird.net/) in sync with the Noctalia palette.

## What it themes

Noctalia renders its palette into Thunderbird's chrome through `userChrome.css`.
The template overrides Thunderbird's layout variables, which cover the toolbars,
folder pane, message list, message header and cards in one place:

- backgrounds, text and separators (`--layout-background-*`, `--layout-color-*`,
  `--layout-border-*`)
- selected folder and message rows (`--selected-item-*`)
- the accent color (`--color-accent-primary`)

It also trims the chrome for tiling setups: the classic menu bar is hidden and
the tab bar, unified toolbar and list rows are made more compact.

Message bodies and the compose window are not themed. They render in their own
documents outside the reach of `userChrome.css`, and Noctalia only ships a
`userChrome` template, not a `userContent` one.

## Setup

1. Enable **Thunderbird** in Noctalia under *Settings -> Templates* (community
   templates), or from `config.toml`:

   ```toml
   [theme.templates]
   community_ids = ["thunderbird"]
   ```

2. Apply a theme (change the wallpaper/palette, or re-apply the current one).
   `apply.sh` writes the rendered file and wires it into every profile.

3. Restart Thunderbird once. `userChrome.css` is only read on startup.

## How the wiring works

`apply.sh` looks for `prefs.js` in the profiles under `~/.thunderbird`, the
Flatpak path and the Snap path. In each profile it:

- prepends `@import "<cache>/noctalia.css";` to `chrome/userChrome.css`
  (creating the file if needed),
- appends
  `user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);`
  to `user.js` if that preference is not set yet.

Both steps are idempotent: re-applying never duplicates a line. Files that are
not writable, for example profiles managed by Home Manager or another Nix module
(read-only symlinks into the store), are left untouched with a warning on stderr.
In that case set the preference and the `@import` from your system configuration
instead.

## Uninstall

Remove the import line from `chrome/userChrome.css`, the
`toolkit.legacyUserProfileCustomizations.stylesheets` line from `user.js`, and
disable the template in Noctalia.
