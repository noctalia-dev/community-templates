# Loupe

Tested against Loupe 50.0 (Flatpak, `org.gnome.Loupe`).

## Flatpak only, deliberately no native entry

`$XDG_CONFIG_HOME/gtk-4.0/gtk.css` is GTK4's system-wide user override path — Noctalia's own
builtin `gtk4` template already writes there, and already defines every named color a
libadwaita app like Loupe needs. A native install gets themed correctly with zero extra work
once that builtin template is enabled; a separate native `[templates.loupe]` entry targeting the
same file would just re-declare it for no benefit, and risks silently wiping whatever the builtin
template wrote if it ever rendered in the other order. So this template only ships the Flatpak
variant.

## Flatpak needs its own copy, mirroring the official template

The Flatpak sandbox can't see that host file — Loupe's own isolated config lives at
`~/.var/app/org.gnome.Loupe/config/gtk-4.0/gtk.css`. `gtk.css` here mirrors the official builtin
`gtk4.css` template's own real values (`/usr/share/noctalia/assets/templates/gtk/gtk4.css`)
rather than a hand-rolled subset, so Flatpak Loupe ends up looking identical to every native
GTK4 app on the system instead of alien — sidebar/overview colors are dropped since Loupe (a
single-view image viewer) has no such UI elements, everything else matches the official template
directly, including using `on_error` (not `on_primary`) for `destructive_fg_color` and the
official `@window_bg_color` reference-variable pattern for backdrop states.

## Not every GTK4 Flatpak app honors this the same way

Confirmed live that Loupe's own `~/.var/app/org.gnome.Loupe/config/gtk-4.0/gtk.css` override
loads correctly. A different GTK4/libadwaita Flatpak app (Lutris) hit a confirmed,
upstream-declined relative-import limitation in a separate investigation (`flatpak/flatpak#3901`)
that silently prevented any override from loading at all. Do not assume a new GTK4 app works
just because it shares a runtime with one that does, or one that does not, test it directly with
an unmistakable color first (`window { background-color: #ff0000; }`) before writing a real
palette.

## Flatpak install (`org.gnome.Loupe`)

`~/.var/app/org.gnome.Loupe/config/gtk-4.0/gtk.css`. No `flatpak override` needed.

## Status

Verified live against Loupe 50.0 (Flatpak) through Noctalia's own real render pipeline
(`community_ids` + local `community-templates/loupe/`), both dark and light mode, and
re-applying twice produces an identical file (idempotent, this template has no hooks so
idempotency is really just "the render is deterministic").
