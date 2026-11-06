# Serein

Serein is a lightweight, 100% native Discord client written in Rust, designed
for fast startup and low overhead without Electron.

## Requirements and installation

Install Serein from its official package repository, then install `jq` with
your distribution's package manager:

```sh
# Debian / Ubuntu
sudo apt install serein jq

# Fedora
sudo dnf install serein jq

# Arch Linux
sudo pacman -S serein jq
```

If you have not configured the Serein package repository yet, run its official
setup script first:

```sh
curl -fsSL https://viceverse-cz.github.io/Serein/setup.sh | sh
```

See the [Serein installation guide](https://github.com/ViceVerse-cz/Serein#linux-installation)
for other installation methods.

## Setup

1. Open Noctalia Settings → Templates.
2. Enable **serein**.
3. In Noctalia Settings → Theme, enable **Sync color scheme** so Serein's
   **System** appearance follows Noctalia's Light/Dark mode.
4. In Serein, choose **System** appearance.
5. Restart Serein after Noctalia renders new palette colors to load the updated
   theme.

The theme package is stored at
`$XDG_DATA_HOME/serein/extensions/themes/noctalia/package.json`. When
`XDG_DATA_HOME` is unset, it is stored at
`~/.local/share/serein/extensions/themes/noctalia/package.json`.
