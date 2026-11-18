# Hermes Agent

Themes [Hermes Agent](https://github.com/NousResearch/hermes-agent) — the CLI, the
Ink TUI and the native desktop app — from the active Noctalia palette.

Hermes reads its colors from a **skin**: a single YAML file that every surface
shares. This template renders that skin, so the agent's background, accent, text
hierarchy, borders, status bar, diffs, syntax highlighting and completion menu all
follow the palette you pick in Noctalia — including the accent color the desktop
app uses for buttons, focus rings and the tool marker.

## Prerequisites

- Hermes Agent installed, with `hermes` on `PATH`.
- A Noctalia palette active (`noctalia msg color-scheme-get` prints it).
  Any source works: `builtin`, `community`, `wallpaper` or `custom`.

## Setup

1. Enable this template in **Settings → Templates**.

2. Select the generated skin once — Hermes applies a skin by name, and the name
   never changes afterwards:

   ```sh
   hermes config set display.skin noctalia
   ```

   `hermes skin list` must show `noctalia` under the user skins. That single
   command is the only manual step: from then on, every palette change rewrites
   the skin and Hermes repaints by itself.

3. Nothing else. No hook, no restart.

## What gets written

| Path | Notes |
| --- | --- |
| `${HERMES_HOME:-$HOME/.hermes}/skins/noctalia.yaml` | The skin. Resolved at apply time, so profiles (`~/.hermes/profiles/<name>/`) write into their own home. |

The rendered file is a normal Hermes skin: keep it, fork it, edit it by hand —
Noctalia overwrites it on the next palette change.

## How changes take effect

Hermes watches the active skin file's modification time, not its contents: a
render that rewrites the file repaints the running CLI, TUI and desktop app
within about a second. Noctalia's engine skips the write when the rendered output
would be identical, so a palette change that lands on the same colors does not
cause a repaint — that is intentional.

## Themes covered

- **Both polarities.** `colors` follows Noctalia's default mode, and the skin also
  ships `light_colors` and `dark_colors` blocks so a light terminal under a dark
  palette (and the reverse) stays coherent instead of flipping to the default
  gold.
- **Accent.** `ui_accent` (and `banner_accent`) take `primary`; `ui_tool`, the
  `●` tool marker, takes `tertiary` so it stays distinct from headings.
- **Semantics.** `ui_ok` / `ui_warn` / `ui_error` and the status bar take the
  palette's terminal green, yellow, bright red and `error`.
- **Diffs.** Added and removed lines are the palette's terminal green and red at
  13% lightness (dark) and 90% lightness (light), desaturated so code stays
  readable over them.
- **Syntax** uses the terminal palette, so string / number / keyword / comment
  never collide with the accent.

## Tuning

The skin exposes no knobs on purpose — it is generated. To change how a role maps
to a color, edit `hermes-skin.yaml` in this directory: every value is a
`{{ colors.<token>.<mode>.hex }}` expression, and Noctalia's filters
(`| set_lightness`, `| desaturate`, `| blend`) apply. To change one color for
good without losing the palette, edit the rendered skin with
`hermes skin set <key> <hex>` — but the next palette change regenerates it.

## Overwrite caveats

- The whole file is replaced on every render. A hand-edited `noctalia.yaml` does
  not survive a palette change; author changes in this template instead.
- If a skin named `noctalia` collides with a Hermes built-in, a built-in wins and
  this one is ignored (there is no built-in with this name today).

## Tested against

- Hermes Agent `ae2a81ccc0` (November 2026), CLI + desktop app on Linux/Wayland.
- Noctalia 5.50.0, custom and wallpaper palettes, dark and light default modes.

## License

MIT, matching the rest of the catalog.
