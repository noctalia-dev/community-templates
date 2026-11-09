# Serein

Serein is a lightweight, 100% native Discord client written in Rust, designed
for fast startup and low overhead without Electron.

## Requirements

- Serein
- jq

```sh
# Debian / Ubuntu
sudo apt install jq

# Fedora
sudo dnf install jq

# Arch Linux
sudo pacman -S jq
```

## Setup

1. Open Noctalia Settings → Templates.
2. Enable **serein**.
3. In Noctalia Settings → Theme, enable **Sync color scheme** so Serein's
   **System** appearance follows Noctalia's Light/Dark mode.
4. In Serein, select the **Noctalia** theme manually and choose **System** appearance.
5. Restart Serein after Noctalia renders new palette colors to load the updated
   theme.

The theme package is stored at
`$XDG_DATA_HOME/serein/extensions/themes/noctalia/package.json`. When
`XDG_DATA_HOME` is unset, it is stored at
`~/.local/share/serein/extensions/themes/noctalia/package.json`.

For the Flatpak version, the theme package is stored at
`~/.var/app/cz.viceverse.serein/data/serein/extensions/themes/noctalia/package.json`.

The `reload.sh` hook writes the rendered theme package to this `package.json` file.
