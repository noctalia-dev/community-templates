# Spicetify — Colorful

A Noctalia v5 color template for the [Colorful](https://github.com/sanoojes/spicetify-colorful) Spicetify theme.

Generates Colorful's `color.ini` from your active Noctalia palette and reapplies Spicetify automatically whenever your theme changes.

## Requirements

- [Spicetify](https://spicetify.app/docs/getting-started) installed and working
- The **[Colorful](https://github.com/sanoojes/spicetify-colorful)** Spicetify theme **MANUALLY** installed at `~/.config/spicetify/Themes/Colorful`

## What it does

- `spicetify_colorful.ini` — maps Noctalia's palette to Colorful's `color.ini` keys.
- `template.toml` — tells Noctalia where to write the generated file (`$XDG_CONFIG_HOME/spicetify/Themes/Colorful/color.ini`) and what to run afterward.
- `apply.sh` — runs `spicetify apply -q --no-restart` so Spotify picks up the new colors without a manual step.

## Manual Installation

1. Add this block to your `config.toml`:

   ```toml
   [theme.templates.user.spicetify]
   input_path = "spicetify_colorful.ini"
   output_path = "$XDG_CONFIG_HOME/spicetify/Themes/Colorful/color.ini"
   post_hook = "spicetify apply -q --no-restart"
   ```

2. Place `spicetify_colorful.ini` in the same directory as your `config.toml`, since `input_path` is resolved relative to it.

## Post-installation

To apply the theme run the commands below:

```sh
spicetify config current_theme Colorful color_scheme noctalia
spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
spicetify apply
```

## Notes

- `apply.sh` runs `spicetify apply --no-restart`, so Spotify won't be force-closed.
  If the theme is already applied, hot-reload it with `Ctrl+Shift+R` instead.
- This template is limited to color values only. Any CSS inconsistencies,
  layout issues, or other formatting concerns are the responsibility of the
  Colorful theme itself and should be reported upstream.
