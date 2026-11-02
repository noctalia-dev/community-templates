#!/usr/bin/env bash
set -euo pipefail

lazydocker_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/lazydocker"
themes_dir="$lazydocker_config_dir/themes"
theme_file="$themes_dir/noctalia.yml"
config_file="$lazydocker_config_dir/config.yml"
# Marks the theme key written by this hook, and holds the lines it replaced so
# undo.sh can restore them. Keep both in sync with undo.sh.
marker="# managed by noctalia - do not touch"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/lazydocker-original-theme.yml"

mkdir -p "$themes_dir" "$(dirname "$state_file")"
touch "$config_file"

# 1. Verify theme file exists
if [ ! -f "$theme_file" ]; then
  echo "noctalia.yml not found" >&2
  exit 1
fi

# 2. Extract the theme block cleanly from rendered theme file
theme_block=$(awk '
  # Detect the top-level "gui:" block starter.
  /^gui[[:space:]]*:/ {
    in_gui = 1
    next
  }

  # If inside gui, look for "theme:" indented by two spaces.
  in_gui && /^  theme[[:space:]]*:/ {
    in_theme = 1
    next
  }

  # While inside the theme block, collect lines indented by at least four spaces.
  in_theme {
    if ($0 ~ /^    /) {
      print
    } else if ($0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]*#/) {
      exit
    }
  }
' "$theme_file")

if [ -z "$theme_block" ]; then
  echo "failed to extract theme from noctalia.yml" >&2
  exit 1
fi

# Create a safe temporary file for the rewrite
tmp_file="$(mktemp)"

# 3. Rebuild config.yml safely using AWK.
# The config file is passed twice: the first pass only detects whether gui.theme
# already exists, so a missing theme is never inserted when one appears later.
awk -v theme_data="$theme_block" -v marker="$marker" -v state_file="$state_file" '
  BEGIN {
    in_gui = 0
    in_theme = 0
    saw_gui = 0
    saw_theme = 0
    has_theme = 0
    scan_gui = 0
    in_old = 0
    managed = 0
    old = ""
  }

  # Lines that belong to (or trail) a theme block and are dropped when it is replaced.
  function discardable(line) {
    return line ~ /^    / || line ~ /^[[:space:]]*$/ || line ~ /^[[:space:]]*#/
  }

  # Pass 1: look for "theme:" inside the top-level gui block.
  # Also, keep a copy of exactly the lines pass 2 will discard so undo.sh can put them back.
  FNR == NR {
    if (in_old) {
      if (discardable($0)) {
        old = old $0 "\n"
        next
      }
      in_old = 0
    }

    if ($0 ~ /^gui[[:space:]]*:/) {
      scan_gui = 1
    } else if ($0 ~ /^[^[:space:]#]/) {
      # A non-comment top-level key ends the gui block.
      scan_gui = 0
    } else if (scan_gui && $0 ~ /^  theme[[:space:]]*:/) {
      has_theme = 1
      in_old = 1
      old = old $0 "\n"
      if (index($0, marker) > 0) {
        managed = 1
      }
    }
    next
  }

  # Print the theme block under gui.
  function print_theme() {
    print "  theme: " marker
    print theme_data
    saw_theme = 1
  }

  {
    # Check if we hit the top-level "gui:" key.
    if ($0 ~ /^gui[[:space:]]*:/) {
      saw_gui = 1
      in_gui = 1
      print
      next
    }

    if (in_gui) {
      # Check if we hit the "theme:" key inside gui.
      if ($0 ~ /^  theme[[:space:]]*:/) {
        print_theme()
        in_theme = 1
        next
      }

      # If we are inside theme, discard old theme lines, blank lines, and comments.
      if (in_theme) {
        if (discardable($0)) {
          next
        }
        in_theme = 0
      }

      # A sibling key is still part of gui. Insert theme before the first
      # sibling when theme is missing, but remain in the gui context.
      if ($0 ~ /^  [^[:space:]#]/) {
        if (!saw_theme && !has_theme) {
          print_theme()
        }
      }

      # A non-comment top-level key ends the gui block.
      if ($0 ~ /^[^[:space:]#]/) {
        if (!saw_theme && !has_theme) {
          print_theme()
        }
        in_gui = 0
      }
    }

    # Print unrelated lines unchanged.
    print
  }

  END {
    # Save what is about to be replaced (an empty file means there was no theme),
    # unless it is our own earlier output. This happens before config.yml is
    # rewritten, and only the first apply over a user theme is recorded.
    if (!managed) {
      printf "%s", old > state_file
      close(state_file)
    }

    # If the file ended while we were inside gui and we never saw theme, print it now.
    if (in_gui && !saw_theme && !has_theme) {
      print_theme()
    } else if (!saw_gui) {
      if (NR > 0) {
        print ""
      }

      print "gui:"
      print_theme()
    }
  }
' "$config_file" "$config_file" >"$tmp_file"

# Write through a symlink instead of replacing it via mv.
if ! cmp -s "$config_file" "$tmp_file"; then
  cat "$tmp_file" >"$config_file"
fi
rm -f "$tmp_file"
