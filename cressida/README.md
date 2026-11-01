# Cressida

A native Cressida theme that follows the Noctalia palette. It covers backgrounds,
text, accents, button hover colors, status colors and code syntax highlighting.
Both dark and light variants are generated in one theme file.

## Requirements

Use a current Cressida build with custom TOML themes and the `hover` and
`on_hover` color keys. The theme uses Cressida's standard XDG configuration path.

## Setup

1. Enable **Cressida** in Noctalia's **Settings > Templates**.
2. In Cressida, open **Settings > Cressida > Themes** and select **Noctalia**.
3. Choose **Dark**, **Light** or **System** under Cressida's **Appearance** settings.

Noctalia creates the theme file and its directory automatically:

```text
$XDG_CONFIG_HOME/cressida/themes/noctalia.toml
```

When `XDG_CONFIG_HOME` is unset, this is
`~/.config/cressida/themes/noctalia.toml`.

Cressida watches the theme directory and reloads valid changes while running.
Palette changes apply without restarting. Its color mode remains controlled by
Cressida's Appearance setting; choose System to follow the desktop's light or
dark preference. Theme selection is per account, so select Noctalia separately
for each account you use.

No shell hook or manual configuration edit is needed. The template does not
change account preferences. Noctalia overwrites the generated file on subsequent
theme changes, so save any personal edits under another theme filename.

## Disable

Disable the template in Noctalia to stop updates. In Cressida, select another
theme. You can then remove `noctalia.toml` if you no longer need it.
