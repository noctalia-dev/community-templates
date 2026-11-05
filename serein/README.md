# Serein

Serein is a lightweight, 100% native Discord client written in Rust. It uses
native rendering and avoids Electron, Node.js and browser-based desktop
runtimes, providing fast startup, low overhead and responsive performance while
supporting direct messages, guilds, friends, voice features and customizable
themes.

Synchronizes Serein's native theme package with the active Noctalia palette.

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

5. The bundled `reload.sh` hook copies the generated package into Serein's
   installed theme directory. Serein does not expose a theme reload IPC, so
   restart Serein manually to load the updated package.

6. If Serein does not exit when you close its window, disable **Keep Serein in
   the system tray** in Serein's settings. When this option is enabled, closing
   the window only hides Serein in the system tray; use the tray menu →
   **Quit** to exit fully.

The generated package contains both dark and light palettes. The active
Noctalia appearance determines which input file is rendered.

## Updating

Noctalia regenerates the output whenever its palette or appearance changes. The
bundled `reload.sh` hook then updates the installed `noctalia` theme package.
No manual re-import is needed after the first import. The hook never closes or
launches Serein; restart Serein manually to apply the updated theme.

## What is themed

The template maps Noctalia surface, text, container, accent, semantic and
mention colors to Serein's theme API. It also disables transparency and blur
and supplies the shared control style used by both appearances.

Tested with Serein `1.0.0-nightly.20261103.74` and Noctalia `5.4.1`.
