#!/usr/bin/env bash
set -euo pipefail

{
  COLOR_FILE="$(dirname "$0")/colors-final"
  [[ -f "$COLOR_FILE" ]] || exit 0

  # 1. Read the file instantly into RAM
  mapfile -t lines < "$COLOR_FILE"
  
  # 2. Extract and clean the target color
  TARGET="${lines[0]//[# ]/}"
  [[ ${#TARGET} -ge 6 ]] || exit 0
  TARGET=${TARGET:0:6}

  TR=$((16#${TARGET:0:2}))
  TG=$((16#${TARGET:2:2}))
  TB=$((16#${TARGET:4:2}))
  
  # 3. Extract the mapping array
  MAPPING="${lines[${#lines[@]}-1]}"

  # 4. Math calculation
  closest=$(
    awk -v r="$TR" -v g="$TG" -v b="$TB" -v m="$MAPPING" '
    BEGIN {
      n = split(m, arr)
      for (i = 1; i <= n; i++) {
        split(arr[i], p, ":")
        cr = strtonum("0x" substr(p[2],1,2))
        cg = strtonum("0x" substr(p[2],3,2))
        cb = strtonum("0x" substr(p[2],5,2))
        d = (r-cr)^2 + (g-cg)^2 + (b-cb)^2

        if (min == "" || d < min) {
          min = d
          name = p[1]
        }
      }
      print name
    }
  ')

  # 5. Ensure user icon directory is created so papirus-folders doesn't need to be called as root
  if [[ ! -d $HOME/.local/share/icons/Papirus ]]; then
    mkdir -p "$HOME/.local/share/icons"
    
    if [[ -d "/usr/share/icons/Papirus" ]]; then
      cp -r "/usr/share/icons/Papirus" "$HOME/.local/share/icons/"
    else
      echo "Error: Papirus Icons are not installed" 1>&2; exit 1
    fi
  fi
 
  # 6. Apply icons instantly
  [[ -n "$closest" ]] && bash "$(dirname "$0")/papirus-folders" -C "$closest" || echo "Error: Failed to apply papirus-folders"
}
