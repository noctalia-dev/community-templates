# Obsidian — Noctalia Community Template

Applies noctalia's generated color palette to [Obsidian](https://obsidian.md) as a CSS snippet.
Both dark and light mode variants are generated, and Obsidian will use whichever matches its
current appearance setting.

## How it works

This template renders a CSS snippet (`noctalia.css`) into each discovered Obsidian vault's
`snippets/` directory. The snippet overrides Obsidian's CSS custom properties to match
noctalia's active palette — backgrounds, text, accents, headings, links, tags, graph view,
and more.

The apply script automatically enables the snippet in each vault's `appearance.json`.

## Vault discovery

The apply script searches `$HOME` (up to 4 directories deep) for `.obsidian/` folders.
If your vault lives deeper or on an external drive, you can add a user template override
in your noctalia config with an explicit `output_path`:

```toml
[theme.templates.user.obsidian_extra]
input_path  = "obsidian/obsidian.css"
output_path = "/mnt/data/MyVault/.obsidian/snippets/noctalia.css"
```

## Requirements

- Obsidian (any recent version with CSS snippet support)
- `python3` (for enabling the snippet in `appearance.json`)

## Notes

- The snippet layers on top of any installed Obsidian theme — it overrides color
  variables without removing your base theme.
- Obsidian hot-reloads CSS snippets from disk on most platforms. If colors don't
  update after a wallpaper change, toggle the snippet off/on in
  Settings → Appearance → CSS Snippets.
