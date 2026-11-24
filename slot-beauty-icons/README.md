# Slot Beauty Icons — Noctalia Community Template

Tints the folder icons of **Slot Beauty Dark Icons V2** with Noctalia's active
palette, so folders follow your wallpaper instead of staying blue.

The original icon pack is never modified. The template builds a sibling theme,
`Slot-Beauty-Dark-Icons-V-2-Noctalia`, next to it and selects that one.

## Requirements

The **Slot Beauty Dark Icons V2** pack should be installed in standard icon paths:

```
~/.local/share/icons/Slot-Beauty-Dark-Icons-V-2
```
*(Also automatically detects `~/.icons/`, `/usr/share/icons/`, and `/usr/local/share/icons/`).*

If the pack lives elsewhere, export `SLOT_BEAUTY_SRC` pointing to it before enabling the template.

Tested against the pack by `l4k1` (`Name=Slot-Beauty-Dark-Icons-V-2`).

## What changes

Only the colourful folder icons under `places/` are rewritten:

| Path | Result |
| --- | --- |
| `places/*/folder*.svg` | Recoloured: the folder body lands exactly on `primary` |
| `places/*/user-desktop.svg` | Recoloured: desktop folder icon lands exactly on `primary` |
| `places/*/user-home.svg` | Recoloured: home folder icon lands exactly on `primary` |
| `places/*/folder*-symbolic.svg` | Untouched (monochrome, tinted at runtime) |
| `places/symbolic/*` | Untouched |
| every other file in the pack | Shared with the original through a symlink |

The derived theme stays in sync with the original pack without re-creating
static directory trees on every theme change.

## Performance, Security, and Atomicity

- **Secure Atomic File Updates**: Each recoloured folder SVG is written to an unguessable
  temporary file created securely via `tempfile.NamedTemporaryFile` in the same directory,
  and atomically swapped into place via `os.replace`. Active directories and files are
  never deleted in-place, eliminating desktop icon flicker and temporary fallback to
  default/Adwaita icons during wallpaper changes.
- **Fast Synchronization**: Theme synchronization and in-memory recoloring runs in
  under 100ms in a single pass. Symlinks are preserved rather than traversed or overwritten.
- **Idempotent Configuration**: GSettings, GTK 3/4 (`settings.ini`), and Qt 5/6 (`qt5ct`/`qt6ct`)
  icon theme settings are only modified when their values actually differ from the target
  theme, avoiding spurious config reloads.

## How the colour is chosen

The palette token is `primary`, taken from the active Noctalia scheme, so the
folders follow wallpaper and theme changes.

Every folder icon is rebuilt around one *anchor* colour — the large, saturated
colour that forms the folder face:

1. The anchor is looked up in `bodies.tsv`, a table precomputed from the
   rendered pixels of this icon pack. It is the same value for every palette,
   because the face of a folder does not change with the theme.
2. The anchor maps exactly onto `primary`.
3. Every other saturated colour keeps its original lightness **offset** from
   the anchor and its saturation **ratio** to it, so gradients, back tabs and
   badges keep their relative tonal structure.
4. Light neutrals (the glyph lines, e.g. `#eff0f1`) stay light and legible.
   Dark neutrals (shadows, base plates) stay dark with a faint tint.
5. Icons without any saturated colour — the small monochrome line-art folders
   at 16/22/24 px — are left exactly as they are, so GTK and Qt keep tinting
   them at runtime.

If an icon is missing from `bodies.tsv` (a different revision of the pack),
the anchor is detected from the file itself instead of skipping the icon.

`bodies.tsv` is regenerated with:

```sh
python3 gen_bodies.py \
  ~/.local/share/icons/Slot-Beauty-Dark-Icons-V-2/places bodies.tsv
```

`gen_bodies.py` needs `rsvg-convert`; it is only needed when the pack changes,
never when the template runs.

## Side effects

Enabling the template:

- creates `~/.local/share/icons/Slot-Beauty-Dark-Icons-V-2-Noctalia`;
- sets the GSettings icon theme (`org.gnome.desktop.interface icon-theme`);
- sets the GTK 3/4 icon theme (`gtk-icon-theme-name`);
- sets the qt5ct/qt6ct icon theme (`icon_theme`) if the respective config file exists;
- records previous values and unset state in `~/.config/noctalia/slot-beauty-icons.state`.

Disabling the template (`undo_hook`):

- restores each recorded setting to its exact previous value;
- removes any setting that was originally unset (and removes generated `settings.ini` if created);
- removes the state file. The derived theme directory is left on disk so re-enabling is instant.

## Notes

- The template is safe to re-run: it rebuilds only when the target colour
  changes, and the rebuild is idempotent.
- The original pack stays untouched at all times.
