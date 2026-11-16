#!/usr/bin/env bash
set -euo pipefail

lxqt_cache_dir="${XDG_CACHE_DIR:-$HOME/.cache}/noctalia/lxqt"
palettes_dir="$lxqt_cache_dir/palettes"
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lxqt/lxqt.conf"

if [[ ! -f $config_file ]]; then
  exit 1
fi

write_in() {
  awk '
    /^\[Palette\]/ {
      in_palette=1
      while ((getline line < "'"$palettes_dir"'/noctalia.conf") > 0) print line
      next
    }
    /^\[/ && in_palette { in_palette=0 }
    !in_palette { print }
  ' $config_file > $config_file.tmp && mv $config_file.tmp $config_file
}

if awk '/\[Palette\]/{found=1; exit} END{exit !found}' $config_file; then
  write_in
else 
  sed -i '$a\\n[Palette]' $config_file
  write_in 
fi
