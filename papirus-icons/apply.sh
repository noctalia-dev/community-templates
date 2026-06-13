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

  # 4. Math calculation (HSV-based)
  closest=$(
    awk -v r="$TR" -v g="$TG" -v b="$TB" -v m="$MAPPING" '
    function rgb2hsv(r,g,b, mx,mn,d,h,s,v,t) {
      r/=255; g/=255; b/=255
      mx = (r>g)?(r>b?r:b):(g>b?g:b)
      mn = (r<g)?(r<b?r:b):(g<b?g:b)
      v = mx
      d = mx - mn
      if (d == 0) { s = 0; h = 0 }
      else {
        s = d / mx
        if (mx == r) {
          t = (g - b) / d
          if (t < 0) t += 6
          h = 60 * t
        } else if (mx == g) {
          h = 60 * (((b - r) / d) + 2)
        } else {
          h = 60 * (((r - g) / d) + 4)
        }
      }
      return h SUBSEP s SUBSEP v
    }
    BEGIN {
      # weights: hue dominates, saturation moderate, value (brightness) least
      WH = 10
      WS = 1
      WV = 0.3

      split(rgb2hsv(r,g,b), tgt, SUBSEP)
      th = tgt[1]; ts = tgt[2]; tv = tgt[3]

      n = split(m, arr)
      for (i = 1; i <= n; i++) {
        split(arr[i], p, ":")
        cr = strtonum("0x" substr(p[2],1,2))
        cg = strtonum("0x" substr(p[2],3,2))
        cb = strtonum("0x" substr(p[2],5,2))

        split(rgb2hsv(cr,cg,cb), c, SUBSEP)
        ch = c[1]; cs = c[2]; cv = c[3]

        dh = th - ch
        if (dh < 0) dh = -dh
        if (dh > 180) dh = 360 - dh
        dh /= 180

        ds = ts - cs
        dv = tv - cv

        # scale hue term by saturation product so greys/low-sat colors
        # do not get distorted by an undefined/meaningless hue
        d = WH * (ts*cs) * dh*dh + WS * ds*ds + WV * dv*dv

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
  [[ -n "$closest" ]] && "$(dirname "$0")/papirus-folders" -C "$closest" || echo "Error: Failed to apply papirus-folders"
}
