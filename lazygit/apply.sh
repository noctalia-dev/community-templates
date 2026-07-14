#!/usr/bin/env bash
set -e

lazygit_folder="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
theme_source="$lazygit_folder/theme.yml"
config_file="$lazygit_folder/config.yml"

if [ ! -f "$theme_source" ]; then
    echo "theme.yml not found"
    exit 1
fi

# get the theme block from the rendered file
theme_block=$(awk '
    /^gui:$/ { in_gui = 1; next }
    in_gui && /^  theme:$/ { in_theme = 1; next }
    in_theme {
        if (/^[^ ]/ || (/^  [^ ]/ && !/^    /)) exit
        print
    }
' "$theme_source")
if [ -z "$theme_block" ]; then
    echo "failed to extract theme from theme.yml"
    exit 1
fi
mkdir -p "$(dirname "$config_file")"
touch "$config_file"
new_section="  theme:
$theme_block"
# inject into the real config
if grep -q '^gui:' "$config_file"; then
    if grep -q '^  theme:' "$config_file"; then
        awk -v new="$new_section" '
            /^  theme:$/ {
                print new
                while ((getline line) > 0) {
                    if (line !~ /^    /) { print line; break }
                }
                next
            }
            { print }
        ' "$config_file" > "$config_file.tmp"
        mv "$config_file.tmp" "$config_file"
    else
        awk -v new="$new_section" '
            /^gui:$/ { print; print new; next }
            { print }
        ' "$config_file" > "$config_file.tmp"
        mv "$config_file.tmp" "$config_file"
    fi
else
    [ -s "$config_file" ] && [ -n "$(tail -c1 "$config_file")" ] && echo >> "$config_file"
    echo "gui:" >> "$config_file"
    echo "$new_section" >> "$config_file"
fi