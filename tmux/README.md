# tmux

Source the generated theme after other tmux theme configuration:

```tmux
source-file -q ~/.config/tmux/themes/noctalia.conf
```

With a custom `XDG_CONFIG_HOME`, replace `~/.config` with its value.

The hook reloads only the default server; running named-socket servers must
source the file themselves. Colors embedded in custom status formats are not replaced.
