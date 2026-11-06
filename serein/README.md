# Serein

Serein is a lightweight, 100% native Discord client written in Rust, designed
for fast startup and low overhead without Electron.

## Requirements

- [Serein](https://github.com/ViceVerse-cz/Serein)
- `jq`

Install `jq` with your distribution's package manager:

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
3. Noctalia writes the generated package to:

   ```text
   $XDG_DATA_HOME/serein/noctalia.serein-extension
   ```

   When `XDG_DATA_HOME` is unset, this resolves to
   `~/.local/share/serein/noctalia.serein-extension`.

4. Import the generated `.serein-extension` file once from **Settings → Themes → Import**.

5. The `reload.sh` hook installs or updates the theme package at
   `$XDG_DATA_HOME/serein/extensions/themes/noctalia/package.json` whenever
   Noctalia renders the template. Restart Serein to load an updated theme.
