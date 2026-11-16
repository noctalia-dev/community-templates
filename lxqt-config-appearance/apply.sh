#!/usr/bin/env bash
set -euo pipefail

lxqt_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/lxqt"
palettes_dir="$lxqt_cache_dir/palettes"
palette_file="$palettes_dir/noctalia.conf"
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lxqt/lxqt.conf"

if [[ -L "$config_file" ]]; then
  config_file=$(readlink -f -- "$config_file")
fi

if [[ ! -f "$config_file" || ! -w "$config_file" ]]; then
  printf 'Error: config file "%s" is missing or not writable.\n' "$config_file" >&2
  exit 1
fi

if [[ ! -r "$palette_file" || ! -s "$palette_file" ]] || ! grep -q '^\[Palette\]' "$palette_file"; then
  printf 'Error: palette file "%s" is missing, empty, or malformed.\n' "$palette_file" >&2
  exit 
fi

write_in() {
  local config_dir tmp_file
  config_dir=$(dirname -- "$config_file")

  if [[ ! -w "$config_dir" ]]; then
    printf 'Error: config directory "%s" is not writable for atomic replacement.\n' "$config_dir" >&2
    return 1
  fi

  tmp_file=$(mktemp "${config_dir}/.lxqt.conf.XXXXXX") || return 1
  trap 'rm -f -- "${tmp_file:-}"' RETURN

  awk -v pal="$palette_file" '
    function emit_palette(   line, status, read_any) {
      while ((status = (getline line < pal)) > 0) {
        print line
        read_any = 1
      }
      close(pal)
      if (status < 0 || !read_any) {
        exit 2
      }
    }
    /^\[Palette\]/ {
      found=1
      in_palette=1
      emit_palette()
      next
    }
    /^\[/ && in_palette {
      in_palette = 0
    }
    !in_palette {
      print
    }
    END {
      if (!found) {
        print ""
        emit_palette()
      }
    }
  ' "$config_file" > "$tmp_file"
  chmod --reference="$config_file" "$tmp_file"
  mv -- "$tmp_file" "$config_file"
}

write_in
