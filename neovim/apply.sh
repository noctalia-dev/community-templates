#!/usr/bin/env bash
set -euo pipefail

nvim_lua_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lua"
plugins_dir="$nvim_lua_dir/plugins"
plugin_file="$plugins_dir/base16.lua"
init_lua="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"

if [ ! -f "$plugin_file" ]; then
    mkdir -p "$plugins_dir"
    cat > "$plugin_file" <<'EOF'
return { 'RRethy/base16-nvim',
  config = function()
    require('matugen').setup()
  end,
}
EOF
fi

if [ -f "$init_lua" ] && ! grep -q "require('matugen')" "$init_lua"; then
    cat >> "$init_lua" <<'EOF'

local ok, matugen = pcall(require, 'matugen')
if ok then matugen.setup() end
EOF
fi

pkill -SIGUSR1 nvim >/dev/null 2>&1 || true
