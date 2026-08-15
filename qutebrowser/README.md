# qutebrowser

Matugen template that themes qutebrowser (completion menu, hints, tabs, statusbar, prompts, messages, downloads bar) to match your current Noctalia color scheme.

## Setup

1. Copy `template.py` into your qutebrowser config folder:
   ```bash
   mkdir -p ~/.config/qutebrowser/noctalia
   cp template.py ~/.config/qutebrowser/noctalia/template.py
   ```

2. Register it with matugen by adding this to your Noctalia user templates config (`~/.config/noctalia/user-templates.toml`):
   ```toml
   [theme.templates.user.qutebrowser]
   input_path  = "~/.config/qutebrowser/noctalia/template.py"
   output_path = "~/.config/qutebrowser/noctalia/colors.py"
   post_hook   = "qutebrowser :config-source"
   ```

3. Tell qutebrowser to load the generated file by adding this line near the top of your `~/.config/qutebrowser/config.py`:
   ```python
   config.source('noctalia/colors.py')
   ```

4. Trigger a theme regeneration (change wallpaper, or re-select the current one) so matugen renders `template.py` into `colors.py` for the first time.

That's it — no manual reload needed after the first run. `post_hook` sends `:config-source` to qutebrowser's IPC socket every time the theme regenerates, so an already-running instance picks up the new colors automatically. If qutebrowser isn't running when the hook fires, this simply launches a fresh instance instead (harmless, just not instant theming until you actually open the browser).

Your color scheme should now update automatically every time Noctalia's theme regenerates.

## Why a helper function is in the template

A few qutebrowser settings (hint label backgrounds, tab bar background, etc.) need an `rgba()` string for transparency, not a bare hex value. matugen only outputs hex, so a small conversion helper is defined directly inside the template:

```python
def hex_to_rgba(hex_color, alpha):
    """Convert a #rrggbb hex string to a qutebrowser-compatible rgba() string."""
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return 'rgba({}, {}, {}, {})'.format(r, g, b, alpha)
```

This has to live in `template.py` itself, not in the generated `colors.py`. Since `colors.py` is fully overwritten on every theme regeneration, adding the function only to the generated file means it disappears the next time the theme changes — and qutebrowser will throw `NameError: name 'hex_to_rgba' is not defined` on the next launch, since a later line in the file calls it. Keeping it in the template ensures it survives every regeneration.

## Notes

- Requires qutebrowser's `config.py` to exist and call `config.load_autoconfig(True)` (the default) so both the generated colors and your own settings load together.
- Tested with qutebrowser v3.7.0 / QtWebEngine 6.11.
