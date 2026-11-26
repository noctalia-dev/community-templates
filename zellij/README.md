# Zellij

Generates a `noctalia` theme for Zellij and the built-in Zellij terminal from Noctalia's terminal colors.

## Setup

Install Zellij and enable **Zellij** in **Noctalia Settings -> Templates**. Select the generated theme in `$XDG_CONFIG_HOME/zellij/config.kdl`:

```kdl
theme "noctalia"
```

For the Zellij terminal, colors set under `terminal { theme { ... } }` in `config.kdl` override the generated ones.

## Output

- `$XDG_CONFIG_HOME/zellij/themes/noctalia.kdl`

Back up any existing custom theme at this path before enabling it. The template does not edit `config.kdl` and runs no hooks.
