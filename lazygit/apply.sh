#!/usr/bin/env bash
set -euo pipefail

lazygit_folder="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
theme_source="$lazygit_folder/theme.yml"
config_file="$lazygit_folder/config.yml"

# 1. Verify theme.yml exists
if [ ! -f "$theme_source" ]; then
    echo "theme.yml not found" >&2
    exit 1
fi

# 2. Extract the theme block cleanly from theme.yml
# This extracts everything under gui -> theme, adjusting to standard YAML indentation
theme_block=$(awk '
    # Detect the "gui:" block starter (allowing spacing/comments)
    /^[[:space:]]*gui[[:space:]]*:/ { in_gui = 1; next }
    
    # If inside gui, look for "theme:"
    in_gui && /^[[:space:]]{2}theme[[:space:]]*:/ { in_theme = 1; next }
    
    # While inside the theme block, collect lines indented by at least 4 spaces
    in_theme {
        if ($0 ~ /^[[:space:]]{4}/) {
            print
        } else if ($0 !~ /^[[:space:]]*$/) {
            # Stop if we hit a non-empty line that is not indented by 4 spaces
            exit
        }
    }
' "$theme_source")

if [ -z "$theme_block" ]; then
    echo "failed to extract theme from theme.yml" >&2
    exit 1
fi

# Prepare the directory and config file
mkdir -p "$(dirname "$config_file")"
touch "$config_file"

# Create a safe temporary file for the rewrite
tmp_file="$(mktemp)"

# 3. Rebuild config.yml safely using AWK
awk -v theme_data="$theme_block" '
BEGIN {
    in_gui = 0
    in_theme = 0
    saw_gui = 0
    saw_theme = 0
}

# Print the theme block under gui
function print_theme() {
    print "  theme:"
    print theme_data
    saw_theme = 1
}

{
    # Check if we hit the top-level "gui:" key
    if ($0 ~ /^[[:space:]]*gui[[:space:]]*:/) {
        saw_gui = 1
        in_gui = 1
        print
        next
    }

    if (in_gui) {
        # Check if we hit the "theme:" key inside gui
        if ($0 ~ /^[[:space:]]{2}theme[[:space:]]*:/) {
            print_theme()
            in_theme = 1
            next
        }

        # If we are inside theme, discard old theme lines (indented by 4+ spaces)
        if (in_theme) {
            if ($0 ~ /^[[:space:]]{4}/ || $0 ~ /^[[:space:]]*$/) {
                next
            }
            # We finished skipping the old theme; reset the flag
            in_theme = 0
        }

        # If we hit a new top-level YAML key (not a comment or empty line)
        # and we have not printed our theme yet, insert it right before this key.
        if ($0 ~ /^[^[:space:]#]/) {
            if (!saw_theme) {
                print_theme()
            }
            in_gui = 0 # Exit gui context
        }
    }

    # Print unrelated lines unchanged
    print
}

END {
    # If the file ended while we were inside gui and we never saw theme, print it now
    if (in_gui && !saw_theme) {
        print_theme()
    }
    # If gui was never found in the entire file, append it cleanly to the end
    else if (!saw_gui) {
        if (NR > 0) print ""
        print "gui:"
        print_theme()
    }
}
' "$config_file" > "$tmp_file"

# Replace the original config file atomically
mv "$tmp_file" "$config_file"