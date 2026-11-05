# iamb

Generate a Noctalia color theme for iamb's Matrix TUI interface.

## Setup

1. Install iamb and create its `$XDG_CONFIG_HOME/iamb/config.toml` before enabling this template. The hook fails if that file is missing.
2. Enable **iamb** in **Noctalia Settings → Templates**.

The template writes `$XDG_CONFIG_HOME/iamb/themes/noctalia.toml`. The Bash post-hook updates the `theme` setting in iamb's `[settings]` section to `"noctalia"`, or adds it if absent.

Other configuration settings are retained. The hook is idempotent and can safely be executed multiple times.

The hook requires `bash`, `awk`, and standard command-line tools (`mktemp`, `cat`, `rm`). It does not download or execute external scripts.

The hook does not restart iamb or send a reload command. Restart iamb if necessary to load the generated theme.

The hook uses `~/.config` when `XDG_CONFIG_HOME` is unset.

