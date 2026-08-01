# Loupe

Tested against Loupe 50.0 (Flatpak, `org.gnome.Loupe`).

## Why this is simpler than a GTK3 app

Loupe is libadwaita/GTK4. Unlike GTK3 apps, where every app defines its own ad-hoc set of
`@define-color` names, libadwaita apps share a small, stable, documented set of named colors
(`window_bg_color`, `accent_color`, `card_bg_color`, and so on) that most GNOME apps read the
same way. This template only needs to redefine those, not reverse engineer an app-specific
palette the way Inkscape or darktable needed.

## Not every GTK4 Flatpak app honors this the same way

Confirmed live that Loupe's own `~/.var/app/org.gnome.Loupe/config/gtk-4.0/gtk.css` override
loads correctly. A different GTK4/libadwaita Flatpak app (Lutris) hit a confirmed,
upstream-declined relative-import limitation in a separate investigation (`flatpak/flatpak#3901`)
that silently prevented any override from loading at all. Do not assume a new GTK4 app works
just because it shares a runtime with one that does, or one that does not, test it directly with
an unmistakable color first (`window { background-color: #ff0000; }`) before writing a real
palette.

## The native entry shares a path with Noctalia's own builtin `gtk4` template

`$XDG_CONFIG_HOME/gtk-4.0/gtk.css` is not Loupe-specific, it is GTK4's system-wide user override
path. On a native (non-Flatpak) install, this is the exact same file Noctalia's own builtin
`gtk4` template already writes to (confirmed live: it holds `@import url("noctalia.css");`).
Shipped anyway, for consistency with every other template in this repo, but be aware this is a
structurally different situation from Inkscape/darktable/GIMP, which each have a real app-specific
theme file. If Noctalia's builtin `gtk4` template is enabled, whichever one renders last wins for
any native GTK4 app on the system, not just Loupe.

## Native install

`~/.config/gtk-4.0/gtk.css`.

## Flatpak install (`org.gnome.Loupe`)

Same relative layout, inside the sandbox's own isolated config:
`~/.var/app/org.gnome.Loupe/config/gtk-4.0/gtk.css`. No `flatpak override` needed.

## Status

Verified live against Loupe 50.0 (Flatpak) through Noctalia's own real render pipeline
(`community_ids` + local `community-templates/loupe/`), both dark and light mode, and
re-applying twice produces an identical file (idempotent, this template has no hooks so
idempotency is really just "the render is deterministic").
