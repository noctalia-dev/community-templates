# Serein

Serein is a lightweight, 100% native Discord client written in Rust, designed
for fast startup and low overhead without Electron.

## Requirements

- [Serein](https://github.com/ViceVerse-cz/Serein)

## Setup

1. Open Noctalia Settings → Templates.
2. Enable **serein**.
3. Noctalia writes the generated package to:

   ```text
   $XDG_DATA_HOME/serein/noctalia.serein-extension
   ```

   When `XDG_DATA_HOME` is unset, this resolves to
   `~/.local/share/serein/noctalia.serein-extension`.

4. In Serein, open **Settings → Themes → Import** and select the generated
   `.serein-extension` file.

5. Restart Serein to load the theme.
