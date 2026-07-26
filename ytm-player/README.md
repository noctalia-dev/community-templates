# ytm-player

Themes [ytm-player](https://pypi.org/project/ytm-player/), a Textual-based terminal YouTube Music
client. Install with `pip install ytm-player` or `pipx install ytm-player`.

`ytm-player` reads `~/.config/ytm-player/theme.toml` independently of its own `config.toml`
(source: `ytm_player/ui/theme.py`'s `ThemeColors._apply_toml_overrides`), so this template writes
straight to that file — no merge into the user's own config, no `apply.sh` needed.

Tested against ytm-player 2.0.0.
