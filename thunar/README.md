# Thunar

This template themes Thunar's GTK 3 interface with the active Noctalia palette. It colors the
window, sidebar, file view, selection states, location buttons, scrollbars, tabs, and menus. The CSS
only targets Thunar widgets (`window.thunar`, `.thunar`); it does not change GTK layout, spacing,
or affect other applications.

## How it works

This template ships as a native Noctalia **GTK 3 extension** (`gtk_extension = "gtk3"`). Noctalia
renders the stylesheet into its `noctalia-extensions/` directory next to `gtk.css` and imports it
automatically through the built-in GTK 3 template.

Because it is managed directly by Noctalia's GTK template:
- It requires no hooks and never touches or rewrites your personal `gtk.css`.
- It loads automatically whenever Noctalia's GTK 3 theming is active, and unloads cleanly when
  disabled.

## Menus and context menus

In GTK 3, menus follow two distinct paths:
- **In-window menus** (such as `Ctrl+M` menubar dropdowns, toolbar action menus, and submenus) are direct descendants of Thunar's window hierarchy and are explicitly themed by this template.
- **Right-click context menus** are spawned by GTK as separate toplevel popup surfaces (`window.popup`) that sit outside Thunar's widget tree. Targeting un-scoped `menu` or `window.popup menu` selectors would leak styling into every other GTK 3 application on the desktop, violating template isolation. Context menus therefore naturally follow the active GTK 3 theme (or Noctalia's global GTK 3 palette if enabled).

## Requirements and status

- Thunar must use GTK 3. The selectors are based on and visually verified against
  Thunar 4.20.9 (Xfce 4.20).
- Noctalia's built-in GTK 3 template must be enabled for GTK extensions to load.
- Restart Thunar (`thunar -q && thunar`) after applying to pick up stylesheet changes.
