# Serein

A lightweight, native Discord desktop client written in Rust, powered by egui and wgpu.

## Requirements

[Serein](https://github.com/ViceVerse-cz/Serein)

## Setup

1. Open Noctalia Settings → Templates.
2. Enable **serein**.
3. Noctalia writes the generated package to:

   ```text
   $XDG_DATA_HOME/serein-theme/noctalia.serein-extension
   ```

   When `XDG_DATA_HOME` is unset, this resolves to
   `~/.local/share/serein-theme/noctalia.serein-extension`.

4. In Serein, open **Settings → Themes → Import** and select the generated
   `.serein-extension` file.

5. If Serein does not exit when you close its window, disable **Keep Serein in
   the system tray** in Serein's settings. When this option is enabled, closing
   the window only hides Serein in the system tray; use the tray menu →
   **Quit** to exit fully.


