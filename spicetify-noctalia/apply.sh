#!/usr/bin/env bash
# Hook for the Noctalia template. Two modes:
#
#   apply.sh output  Print where noctalia.js goes: Spicetify's own Extensions
#                    folder, asked from Spicetify (`spicetify path userdata`).
#   apply.sh apply   Push the rendered extension into Spotify. The first time,
#                    enable it in Spicetify's config (`spicetify config
#                    extensions noctalia.js` + `spicetify apply --no-restart`);
#                    after that only `spicetify refresh -e`.
#
# If the user removes the extension from Spicetify by hand after it was
# installed, it is not added back: the hook explains how to re-enable it.
# undo.sh reverts everything this script adds.
#
# Test overrides: SPICETIFY_USERDATA, SPICETIFY_CONFIG.
set -euo pipefail
shopt -s inherit_errexit # keep `set -e` inside $(...) too

EXT="noctalia.js"

warn() { echo "Warning: $*" >&2; }

command -v spicetify >/dev/null || { warn "Spicetify is not installed (https://spicetify.app)"; exit 1; }

# Spicetify's output, without color codes, last line only.
spice_value() { { "$@" 2>/dev/null || true; } | sed 's/\x1b\[[0-9;]*m//g' | tail -n1 | tr -d '\r'; }

userdata() {
  local dir="${SPICETIFY_USERDATA:-$(spice_value spicetify path userdata)}"
  if [ -z "$dir" ] || [ ! -d "$dir" ]; then
    warn "could not find Spicetify's folder (spicetify path userdata)"
    exit 1
  fi
  printf '%s' "$dir"
}

# Spicetify's Extensions folder, resolved to its real path. A symlinked setup
# (e.g. dotfiles) is fine as long as the folder really resolves inside
# Spicetify's own folder; anything that escapes it is refused, so nothing is
# ever written or deleted outside it.
extensions_dir() {
  local base real_base ext real_ext
  base="$(userdata)"
  real_base="$(realpath -e -- "$base")"
  ext="$base/Extensions"
  if [ ! -e "$ext" ] && [ ! -L "$ext" ]; then
    mkdir -- "$ext"
  fi
  real_ext="$(realpath -e -- "$ext" 2>/dev/null)" || { warn "Spicetify's Extensions path is a broken link: $ext"; exit 1; }
  [ -d "$real_ext" ] || { warn "Spicetify's Extensions path is not a folder: $real_ext"; exit 1; }
  case "$real_ext/" in
    "$real_base"/*) ;;
    *) warn "Spicetify's Extensions folder resolves outside Spicetify's folder ($real_ext); refusing to write there"; exit 1 ;;
  esac
  printf '%s' "$real_ext"
}

# Refuse a path that is a symlink: writing through it would change another file.
not_symlink() {
  if [ -L "$1" ]; then
    warn "refusing to write $1: it is a symlink"
    exit 1
  fi
}

config_file() {
  local file="${SPICETIFY_CONFIG:-$(spice_value spicetify -c)}"
  [ -f "$file" ] || { warn "Spicetify config not found: ${file:-<none>}"; exit 1; }
  printf '%s' "$file"
}

setting() { sed -n "s/^$1[[:space:]]*=[[:space:]]*//p" "$2" | head -n1 | tr -d '[:space:]'; }

listed() { case "|$(setting extensions "$1")|" in *"|$EXT|"*) return 0 ;; *) return 1 ;; esac; }

# Run a Spicetify command; on failure show its own message plus the usual fix.
run() {
  local out
  if ! out="$("$@" 2>&1)"; then
    out="$(printf '%s' "$out" | sed 's/\x1b\[[0-9;]*m//g' | tr '\n' ' ')"
    warn "'$*' failed: $out (if Spotify was updated or never patched, run: spicetify backup apply)"
    exit 1
  fi
}

case "${1:-apply}" in
  output)
    dir="$(extensions_dir)" # exits here (no path printed) when the checks fail
    not_symlink "$dir/$EXT"
    echo "$dir/$EXT"
    ;;

  apply)
    config="$(config_file)"
    dir="$(extensions_dir)"
    marker="$dir/.noctalia-installed"
    not_symlink "$marker"

    if ! listed "$config"; then
      if [ -e "$marker" ]; then
        warn "the Noctalia extension was removed from Spicetify. Re-enable it with: spicetify config extensions $EXT && spicetify apply (or disable this template)"
        exit 1
      fi
      run spicetify config extensions "$EXT"
      run spicetify -q apply --no-restart
      : > "$marker"
      echo "Noctalia extension enabled in Spicetify; restart Spotify once to load it." >&2
    else
      : > "$marker"
      run spicetify -q refresh -e
    fi

    # Spotify only uses the --spice-* colors when Spicetify replaces colors.
    if [ "$(setting replace_colors "$config")" != "1" ] || [ -z "$(setting current_theme "$config")" ]; then
      warn "Spicetify has no active theme or replace_colors is off, so Spotify ignores theme colors. Run: spicetify config replace_colors 1 and pick a theme"
      exit 1
    fi
    ;;

  *)
    echo "usage: apply.sh [output|apply]" >&2
    exit 2
    ;;
esac
