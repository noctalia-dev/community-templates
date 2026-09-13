# Musicfox

Keeps [musicfox](https://github.com/go-musicfox/go-musicfox) (NetEase Cloud Music TUI
player) aligned with the active Noctalia palette.

## Setup

1. Run `musicfox` once so `~/.config/go-musicfox/config.toml` exists, then enable the
   Musicfox template in Noctalia (Settings -> Templates).
2. On the next theme change the template renders `noctalia.toml` into
   `$XDG_CONFIG_HOME/go-musicfox/themes/` and sets `[theme] activeTheme = "Noctalia"` in
   `config.toml`. Switch back to another theme anytime by editing that line; the hook
   re-activates Noctalia on the next palette change.

No restart needed: musicfox picks the theme up on its next launch (themes are read at
startup). Both the dark and light musicfox variants are written, so the TUI follows your
terminal background.

## Notes

- The generated file is `$XDG_CONFIG_HOME/go-musicfox/themes/noctalia.toml`; it is
  overwritten on every theme change — do not edit it by hand.
- Visualizer colors are palette-driven; set `visualizerColorStart`/`End` to `"random"`
  in the theme file if you prefer the random mode.
- Tested with musicfox 5.1.0 / Noctalia 5.1.0.
