# VLC

Makes VLC 3 (native Qt interface, not the skins interface) use the Noctalia palette.

VLC 3 is a Qt5 app, but many Wayland setups export `QT_QPA_PLATFORMTHEME=qt6ct`, which Qt5 cannot load. This template
does not render a palette of its own. It relies on the built-in **Qt** template, which writes the qt5ct color scheme,
and only makes sure VLC picks that scheme up:

- Renders a `vlc.desktop` override to `~/.local/share/applications` that starts VLC with
  `QT_QPA_PLATFORMTHEME=qt5ct`. It is a copy of VLC 3.0's own entry with only the `Exec` line changed.
- Turns off VLC's own "Use a dark palette" option (`qt-dark-palette` in `vlcrc`), which replaces the qt5ct palette
  with a fixed gray and blue one.

## Setup

1. Enable the built-in **Qt** template in Settings -> Templates. The hook fails with an error if
   `~/.config/qt5ct/colors/noctalia.conf` does not exist.
2. Install `qt5ct`. In it, set the style to `Fusion`, enable **Use custom palette** and point it at
   `~/.config/qt5ct/colors/noctalia.conf`.
3. Enable this template and start VLC from the application launcher. From a terminal, run
   `QT_QPA_PLATFORMTHEME=qt5ct vlc`.

Running VLC instances pick up new colors after a restart. Leave "Force window style" in VLC's interface settings on
the system default or `qt5ct-style`.

## Limits

- Only the native interface is themed. The video area, the cone icons and skins (`.vlt`) keep their own colors.
- Under Wayland compositors VLC 3 runs through Xwayland, so its title bar is drawn by the compositor and is not
  themed.
- The `vlc.desktop` override is a snapshot of VLC 3.0's entry, so it will not follow later changes to the system one.
