# tmux

Noctalia colors for native tmux styles, without changing status content or layout.

## Setup

Add this after any other theme configuration:

```tmux
source-file -q ~/.config/tmux/themes/noctalia.conf
```

For a custom `XDG_CONFIG_HOME`:

```tmux
source-file -q "$XDG_CONFIG_HOME/tmux/themes/noctalia.conf"
```

The post-hook reloads the default tmux server. Named sockets need to source the
file themselves. Other themes and formats with embedded colors may override it.

The generated file exposes its Material color roles as `@noctalia_*` user
options for custom status formats.
