# Spotifast

Themes [Spotifast](https://github.com/crmne/spotifast) with the active
Noctalia palette. The generated palette covers Spotifast's background layers,
text, accents, outlines, semantic colors, overlay, and shadow roles.

## Setup

1. Launch Spotifast once so its configuration directory exists.
2. Enable the Spotifast template in Noctalia.
3. In Spotifast, open **Settings → Appearance → Theme** and select
   `noctalia.json`.

The template reloads a running Spotifast instance after each Noctalia palette
change. If Spotifast is closed, the generated palette is loaded the next time
it starts.

Album-art tinting is independent of custom palettes. Disable **Accent from
album art** in Spotifast's Appearance settings when every surface should keep
the Noctalia colors.

## Output paths

- Native: `$XDG_CONFIG_HOME/fastpotify/themes/noctalia.json`
- Flatpak: `~/.var/app/rocks.spotifast.Spotifast/config/fastpotify/themes/noctalia.json`

The `fastpotify` directory is intentional and is retained by Spotifast for
compatibility with earlier releases.

Custom themes require Spotifast 0.8.0 or newer.

## Testing locally

Before this template is merged, configure it as a user template in
`~/.config/noctalia/config.toml` using absolute paths to this checkout:

```toml
[theme.templates.user.spotifast]
input_path_modes = { dark = "/path/to/community-templates/spotifast/spotifast-dark.json", light = "/path/to/community-templates/spotifast/spotifast-light.json" }
output_path = "$XDG_CONFIG_HOME/fastpotify/themes/noctalia.json"
post_hook = "spotifast reload-themes >/dev/null 2>&1 || true"
```

Confirm that Noctalia sees it, then apply the current palette:

```sh
noctalia theme --list-templates
noctalia msg templates-apply
```

Check that the output is valid JSON, select `noctalia.json` in Spotifast, and
run `spotifast reload-themes`. Test both dark and light Noctalia modes, and
apply the template twice to verify that the output remains valid.
