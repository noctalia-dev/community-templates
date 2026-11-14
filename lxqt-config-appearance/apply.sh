#!/usr/bin/env bash
set -euo pipefail

lxqt_cache_dir="${XDG_CACHE_DIR:-$HOME/.cache}/noctalia/lxqt"
palettes_dir="$lxqt_cache_dir/palettes"
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lxqt/lxqt.conf"
palette_file="$palettes_dir/noctalia.conf"

mkdir -p "$palettes_dir"
touch "$config_file" "$palette_file"

if awk '/\[Palette\]/{found=1; exit} END{exit !found}' $config_file; then
  awk '
    /^\[Palette\]/ {
      in_palette=1
      while ((getline line < "'"$palettes_dir"'/noctalia.conf") > 0) print line
      next
    }
    /^\[/ && in_palette { in_palette=0 }
    !in_palette { print }
  ' $config_file > $config_file.tmp && mv $config_file.tmp $config_file
else 
  awk -i inplace '1; END{print "\n[Palette]"}' $config_file
  awk '
    /^\[Palette\]/ {
      in_palette=1
      while ((getline line < "'"$palettes_dir"'/noctalia.conf") > 0) print line
      next
    }
    /^\[/ && in_palette { in_palette=0 }
    !in_palette { print }
  ' $config_file > $config_file.tmp && mv $config_file.tmp $config_file
fi
