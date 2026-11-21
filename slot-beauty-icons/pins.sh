#!/usr/bin/env bash
# Icon-theme pins kept outside GTK, Qt and GSettings.
#
# Rofi, xsettingsd, KDE, hyprfm and the compositor startup lines each keep
# their own copy of the icon theme name. Updating only GSettings leaves those
# windows showing the untinted pack, so every pin that already exists is
# rewritten to the derived theme. A pin that is not there is never created,
# and undo puts the recorded value back.
#
# Rows are: state key | file | read regex | write regex. The write regex keeps
# the quoting style of the original line; __VALUE__ is the new value.

pin_table() {
  cat <<'PINS'
rofi|__CONFIG_HOME__/rofi/config.rasi|s@^[[:space:]]*icon-theme:[[:space:]]*"([^"]*)".*$@\1@p|s@^([[:space:]]*icon-theme:[[:space:]]*)"[^"]*"@\1"__VALUE__"@
xsettingsd|__CONFIG_HOME__/xsettingsd/xsettingsd.conf|s@^[[:space:]]*Net/IconThemeName[[:space:]]+"([^"]*)".*$@\1@p|s@^([[:space:]]*Net/IconThemeName[[:space:]]+)"[^"]*"@\1"__VALUE__"@
niri|__CONFIG_HOME__/niri/config.kdl|s@^[[:space:]]*spawn-at-startup "gsettings" "set" "org.gnome.desktop.interface" "icon-theme" "([^"]*)".*$@\1@p|s@^([[:space:]]*spawn-at-startup "gsettings" "set" "org.gnome.desktop.interface" "icon-theme" )"[^"]*"@\1"__VALUE__"@
hyprland|__CONFIG_HOME__/hypr/hyprland.lua|s@^[[:space:]]*hl.exec_cmd\("gsettings set org.gnome.desktop.interface icon-theme ([^[:space:]"]+)"\).*$@\1@p|s@^([[:space:]]*hl.exec_cmd\("gsettings set org.gnome.desktop.interface icon-theme )[^[:space:]"]+@\1__VALUE__@
kdeglobals|__CONFIG_HOME__/kdeglobals|s@^Theme=([^[:space:]]*).*$@\1@p|s@^(Theme=)[^[:space:]]*@\1__VALUE__@
kdeglobals_hypr|__CONFIG_HOME__/kdeglobals.hypr|s@^Theme=([^[:space:]]*).*$@\1@p|s@^(Theme=)[^[:space:]]*@\1__VALUE__@
hyprfm|__CONFIG_HOME__/hyprfm/config.toml|s@^[[:space:]]*icon_theme[[:space:]]*=[[:space:]]*'([^']*)'.*$@\1@p|s@^([[:space:]]*icon_theme[[:space:]]*=[[:space:]]*)'[^']*'@\1'__VALUE__'@
PINS
}

# The table with the config home resolved.
pin_rows() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local row
  while IFS= read -r row; do
    printf '%s\n' "${row//__CONFIG_HOME__/$config_home}"
  done < <(pin_table)
}

# Print the value a pin currently holds, or nothing when there is no pin.
pin_value() { # file read-regex
  local file="$1" read_re="$2"
  [[ -f "$file" ]] || return 0
  sed -n -E "$read_re" "$file" | head -n1
}

# Write a value into a pin, keeping the quoting style of the line.
pin_write() { # file write-regex value
  local file="$1" write_re="$2" value="$3"
  [[ -f "$file" && -n "$value" ]] || return 0
  sed -i -E "${write_re//__VALUE__/$value}" "$file"
}
