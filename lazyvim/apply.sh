#!/usr/bin/env bash
#
# apply.sh — wires Noctalia's noctalia colourscheme into LazyVim.
#
# The requires_path gate ($XDG_CONFIG_HOME/nvim/lazyvim.json, which LazyVim
# creates in every starter config) guarantees LazyVim is set up before
# this runs.
#
# Behaviour:
#   - If no file under lua/plugins/ references noctalia, write
#     lua/plugins/noctalia.lua with a minimal spec that sets LazyVim's
#     colorscheme to "noctalia".
#   - If any spec already references noctalia, do nothing (idempotent).
#   - If another spec already sets a colorscheme, warn on stderr: lazy.nvim
#     merges opts, so the user should pick one.
#   - SIGUSR1 is sent to running Neovim sessions so they reload the palette.

set -euo pipefail

xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
plugins_dir="$xdg_config/nvim/lua/plugins"
spec_file="$plugins_dir/noctalia.lua"

if ! grep -rqs 'noctalia' "$plugins_dir"; then
  # Skip specs disabled the LazyVim-starter way (`if true then return {} end`).
  others=""
  while IFS= read -r f; do
    grep -qF 'if true then return {} end' "$f" || others+="$f"$'\n'
  done < <(grep -rlsE '^[^-]*colorscheme[[:space:]]*=' "$plugins_dir" || true)
  if [ -n "$others" ]; then
    echo "lazyvim: another spec also sets a colorscheme; remove it to let noctalia win:" >&2
    printf '%s' "$others" >&2
  fi
  mkdir -p "$plugins_dir"
  cat >"$spec_file" <<'EOF'
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "noctalia",
    },
  },
}
EOF
fi

pkill -SIGUSR1 -x nvim >/dev/null 2>&1 || true
