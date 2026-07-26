# fastfetch

Themes [fastfetch](https://github.com/fastfetch-cli/fastfetch) — sets `display.color.keys`,
`display.color.title`, `display.percent.color.{green,yellow,red}` and `logo.color.{1,2}`.

fastfetch's config (`~/.config/fastfetch/config.jsonc`) has no include/merge directive, so
`apply.sh` merges the rendered color object into the user's real config.jsonc directly (`jq -s
'.[0] * .[1]'`), preserving everything else in it (modules list, custom module config, etc.).

**Known limitation: strict JSON only, not full JSONC.** `jq` (used for the merge) only parses
strict JSON — `//`/`/* */` comments and trailing commas, both valid JSONC, will make `apply.sh`
fail. It fails loudly with a clear message in that case rather than silently corrupting the file
or applying nothing with no explanation. If your `config.jsonc` uses comments, remove them to use
this template (fastfetch's own `--gen-config`/`--gen-config-force` output has none by default).
Also fails loudly (rather than auto-creating one) if `config.jsonc` doesn't exist at all yet —
run fastfetch once first to generate a default config.

**Idempotency note**: the merge is guarded by comparing only the `logo`/`display` sub-objects
semantically (`jq -S`), not the whole file's raw bytes — a naive whole-file `cmp` after a `jq`
merge will never actually match hand-formatted JSON (`jq` re-serializes with its own canonical
formatting), which silently defeats the guard and rewrites the file on every apply regardless of
whether colors changed. Verified idempotent: running `apply.sh` twice with unchanged colors
leaves the file's mtime and content completely untouched.

Tested against fastfetch 2.66.0.
