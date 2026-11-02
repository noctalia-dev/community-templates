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

The `theme:` key written by the hook carries a `# managed by noctalia - do not touch` comment, which is how the hook recognizes its own output.
The first time the hook replaces a `gui.theme` you wrote yourself, it saves exactly the replaced lines (including comments inside that block) to `$XDG_STATE_HOME/noctalia/lazydocker-original-theme.yml` (`~/.local/state/noctalia/...` by default).
Later runs never overwrite that save, since the theme they find is already managed.

Disabling the template runs `undo.sh`.
It only touches a `gui.theme` carrying the marker: the saved lines are put back, or the block is removed if there was no theme before.
Everything else in `config.yml`, including edits made while the template was enabled, is left alone.
Without the marker, or without a config, it does nothing, so it is safe to retry.
If the saved file was deleted, the managed block is simply removed.
If you edit the managed block yourself while the template is enabled, the next theme change overwrites it, and disabling restores the pre-Noctalia theme.
To take over the theme permanently, delete the marker comment.

The hook writes through config symlinks.
Standard tools including `awk`, `mktemp`, and `cmp` are required.
No command is provided to reload a running lazygit instance.
