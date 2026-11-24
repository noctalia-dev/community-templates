# Yazi

Generates a Noctalia flavor for Yazi's interface, file icons and syntax-highlighted previews. The flavor uses glyph icons, so use a font that contains those glyphs, such as a Nerd Font, for complete icon display.

## Setup

Install Yazi, then enable **Yazi** in **Noctalia Settings -> Templates**. The post-hook selects the generated flavor for both dark and light modes automatically.

## Output paths

- `$XDG_CONFIG_HOME/yazi/flavors/noctalia.yazi/flavor.toml`
- `$XDG_CONFIG_HOME/yazi/flavors/noctalia.yazi/tmtheme.xml`

## Configuration changes

The Bash hook creates `$XDG_CONFIG_HOME/yazi/theme.toml` if needed, or updates its `[flavor]` section to contain:

```toml
[flavor]
dark = "noctalia"
light = "noctalia"
```

Existing dark/light flavor choices are replaced; missing keys or the section itself are added. Other settings are retained. The hook uses `awk`, `mktemp`, `cmp` and `sort`, writes through symlinks, and makes no backup. Back up an existing `theme.toml` before enabling the template. Existing explicit theme overrides remain in place.

With `XDG_CONFIG_HOME` unset, the hook uses `~/.config`.

## Live reload

With Yazi 26.5.6 or newer, the hook then runs `ya emit-to 0 app:theme`, which makes every running Yazi instance reload its theme in place, so colors follow wallpaper changes without restarting Yazi. Older versions are detected through `ya --version` and skipped; restart Yazi to see new colors there. When no Yazi is running, the command does nothing.
