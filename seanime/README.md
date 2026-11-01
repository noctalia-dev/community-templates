# Seanime

Writes the active Noctalia palette to `~/.local/state/noctalia/seanime/palette.css`
(`$XDG_STATE_HOME/noctalia/seanime/palette.css`).

The file is a flat list of `--nt-*` custom properties holding Noctalia's Material roles. A
Seanime plugin turns them into Seanime's own variables — the flat ones *and* the
`--color-brand-*` / `--color-gray-*` scales its UI is built from:

**[Noctalia Theme plugin](https://github.com/Below-Z3R0/seanime-noctalia-theme)** — requires
Seanime 3.10+ and the plugin's file-system permission. The template alone does not change
anything in Seanime.

Roles exported: `mode`, `primary`, `primary_container`, `secondary`, `tertiary`, `error`,
`surface`, `on_surface`, `surface_container` (plus `_low` / `_high`), `on_surface_variant`,
`outline` and their `on_*` pairs. A role the plugin does not consume is harmless; renaming one
drops the matching Seanime variable.

## Seanime in Docker

The plugin reads the file **inside the Seanime container**, so the Noctalia state directory has
to be mounted there:

```yaml
volumes:
  - ${XDG_STATE_HOME:-$HOME/.local/state}/noctalia:/home/seanime/.local/state/noctalia:ro
```

Without it the plugin reports `Not found`: the path exists on the host, not in the container.
