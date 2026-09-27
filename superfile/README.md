# superfile

[superfile](https://github.com/yorukot/superfile) is a terminal file manager.
This template writes a complete theme into `~/.config/superfile/theme/noctalia.toml`,
then keeps the user's `~/.config/superfile/config.toml` pointed at it via `theme = "noctalia"`.

## Notes

- superfile ships a default TOML into `~/.config/superfile/` on first launch.
  Run `spf` once before enabling this template so the config file actually
  exists — the post-hook will refuse to run otherwise.
- `code_syntax_highlight` is set to `catppuccin` (a Chroma style). Override it
  in your `superfile` config if you want a different style.
- The theme lives at `theme/noctalia.toml`, mirroring how superfile addresses
  built-in themes by name.
