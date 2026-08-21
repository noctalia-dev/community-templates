# tmux

Noctalia renders a native tmux color scheme while leaving status content,
formats, separators, icons and key bindings untouched.

## Setup

Add this after any other theme configuration in `~/.tmux.conf` or
`$XDG_CONFIG_HOME/tmux/tmux.conf`:

```tmux
source-file -q ~/.config/tmux/themes/noctalia.conf
```

If `XDG_CONFIG_HOME` points somewhere other than `~/.config`, use this instead:

```tmux
source-file -q "$XDG_CONFIG_HOME/tmux/themes/noctalia.conf"
```

New theme renders are loaded into the default running tmux server. Named or
custom-socket servers need to source the generated file themselves.

Other tmux color schemes may override these styles. Disable them, or keep the
Noctalia `source-file` line after them. Formats containing embedded colors also
take precedence over the native tmux style options.

The generated file exposes its Material color roles as `@noctalia_*` user
options for custom status formats.
