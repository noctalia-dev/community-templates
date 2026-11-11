# Halloy

Themes Halloy's interface, message buffers, text, and buttons with Noctalia colors.

Enable **halloy** in **Noctalia Settings -> Templates**. The theme is written to `$XDG_CONFIG_HOME/halloy/themes/noctalia.toml` (`~/.config/halloy/themes/noctalia.toml` by default).

## Setup and hook

Install Halloy and create `$XDG_CONFIG_HOME/halloy/config.toml` before enabling; the Bash hook fails if it is missing. The hook uses `awk` to set the root-level `theme = "noctalia"` before any TOML sections, replacing an existing root theme selection or inserting one. Section-local settings are left alone.

Back up your config first; the hook creates no backup. It then sends `SIGUSR1` only to your processes named exactly `halloy` that have installed a handler for that signal. This lets running instances reload their configuration while leaving instances still initializing alone. It requires procps-ng's `pkill` with `--require-handler` support; no application restart is performed.
