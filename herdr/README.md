# Herdr

Splices a Noctalia `[theme]` / `[theme.custom]` block into
`~/.config/herdr/config.toml` and reloads a running server.

Tested against Herdr 0.8.0 and Noctalia v5.0.0.

## Enable

1. Enable this template in Noctalia (Settings → Templates, or a user-template pointer).
2. Re-apply the current theme (`noctalia msg templates-apply`) or change palette.
3. If Herdr is running, the hook calls `herdr server reload-config`. Otherwise the
   theme applies on next start.

## What the hook does

`apply.sh` replaces a marked block (`# noctalia-herdr-theme-begin` …
`# noctalia-herdr-theme-end`). On first run it drops a pre-existing `[theme]`
table so keys are not duplicated.

If `config.toml` is a symlink, the hook replaces it with a regular file first
so palette hex is not written through the link.

```sh
bash apply.sh dark    # or light
bash apply.sh backup  # one-time original config snapshot
bash apply.sh restore # Herdr must be stopped
```

## Limits

Herdr 0.8.0 does not accept `sidebar_bg` / `active_row_bg` / `selection_bg`.
Empty sidebar cells follow the **host terminal** default background.

## Restore

Original config is snapshotted once under
`$XDG_DATA_HOME/noctalia/herdr/backups/`. Restore only with Herdr quit.
