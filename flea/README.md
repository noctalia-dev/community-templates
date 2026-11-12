# Flea

Renders the active Noctalia palette as a Flea theme, writing the generated
`colors.toml` to Omarchy's current theme directory.

The template maps Noctalia's primary, secondary and outline colors to Flea's
accent, selection and muted colors. Surface and foreground tokens control the
background and text colors, while Noctalia's terminal palette supplies the
tag colors.

Flea: [github.com/thisisgm/flea](https://github.com/thisisgm/flea)

The generated file is written to:

`$XDG_STATE_HOME/omarchy/current/theme/colors.toml`

No manual color editing is needed. When the active Noctalia palette changes,
the template regenerates `colors.toml` with the updated colors.
