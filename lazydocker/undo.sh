#!/usr/bin/env bash
set -euo pipefail

lazydocker_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/lazydocker"
config_file="$lazydocker_config_dir/config.yml"
# Keep both in sync with apply.sh.
marker="# managed by noctalia - do not touch"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/lazydocker-original-theme.yml"

if [ -f "$config_file" ]; then
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' EXIT

  # Only a gui.theme key carrying our marker is touched. It is replaced by the
  # lines apply.sh saved, or removed when there was no theme (or the save is gone).
  # Without a marker, nothing matches and the file is copied unchanged.
  awk -v marker="$marker" -v state_file="$state_file" '
    BEGIN {
      while ((getline line < state_file) > 0) {
        orig[++orig_n] = line
      }
      close(state_file)
    }

    {
      if ($0 ~ /^gui[[:space:]]*:/) {
        in_gui = 1
        gui_at = out_n + 1
      } else if ($0 ~ /^[^[:space:]#]/) {
        in_gui = 0
      }

      # Skip the children of the managed block; apply.sh wrote nothing else.
      if (in_managed) {
        if ($0 ~ /^    /) {
          next
        }
        in_managed = 0
      }

      if (in_gui && $0 ~ /^  theme[[:space:]]*:/ && index($0, marker) > 0) {
        in_managed = 1
        removed = 1
        for (i = 1; i <= orig_n; i++) {
          out[++out_n] = orig[i]
        }
        next
      }

      out[++out_n] = $0
    }

    END {
      # apply.sh may have created gui only to hold the theme: drop it again when
      # nothing else is left in it, and the blank line that was added before it.
      skip = 0
      if (removed && orig_n == 0 && gui_at) {
        i = gui_at + 1
        while (i <= out_n && out[i] ~ /^[[:space:]]*$/) {
          i++
        }
        if (i > out_n) {
          out_n = gui_at - 1
          while (out_n > 0 && out[out_n] ~ /^[[:space:]]*$/) {
            out_n--
          }
        } else if (out[i] ~ /^[^[:space:]#]/) {
          skip = gui_at
        }
      }

      for (i = 1; i <= out_n; i++) {
        if (i != skip) {
          print out[i]
        }
      }
    }
  ' "$config_file" >"$tmp_file"

  # Write through a symlink instead of replacing it via mv.
  if ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
  fi
fi

# Last, so a failed run above is retried with the saved lines still available.
rm -f -- "$state_file"
