# lazydocker

Applies Noctalia colors to [lazydocker](https://github.com/jesseduffield/lazydocker/tree/master).

Enable **lazydocker** in **Noctalia Settings -> Templates**.
The generated theme is in `$XDG_CONFIG_HOME/lazydocker/themes/noctalia.yml` (`~/.config/lazydocker/themes/noctalia.yml` by default).

## Setup and hook

This theme mirrors the setup used for lazygit template that was implemented before, as lazydocker follows the same configuration style.
All credits for the existing logic in the `apply.sh` hook go to the original author.
Only references to lazygit have been changed to lazydocker.

Install lazydocker.
The Bash hook creates `$XDG_CONFIG_HOME/lazydocker/config.yml` if needed, then uses `awk` to copy the generated `gui.theme` block into it.
Existing `gui.theme` content is replaced, while unrelated settings are retained; a missing `gui` or `theme` block is added.

The merge expects block-style YAML with a top-level `gui:` key, a two-space-indented `theme:` key, and theme entries indented at least four spaces.
Use that layout in an existing config rather than inline YAML mappings.

The hook makes two passes over the existing `config.yml` to ensure the `gui:` block does not already contain a `theme:` key.

Back up your config before enabling: the hook creates no backup and removes comments within the old theme block along with its settings.
It writes through config symlinks.
Standard tools including `awk`, `mktemp`, and `cmp` are required.
No command is provided to reload a running lazygit instance.
