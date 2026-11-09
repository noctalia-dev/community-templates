#!/usr/bin/env bash
# Reverts what apply.sh added: takes noctalia.js out of Spicetify's extension
# list (only if it is there), deletes the generated file and the install
# marker, and re-applies Spicetify without restarting Spotify.
# Safe to run any number of times; a no-op when there is nothing to undo.
# Never deletes anything outside Spicetify's folder (symlinks are resolved
# and checked first).
#
# Test overrides: SPICETIFY_USERDATA, SPICETIFY_CONFIG.
set -euo pipefail
shopt -s inherit_errexit

EXT="noctalia.js"

command -v spicetify >/dev/null || exit 0

spice_value() { { "$@" 2>/dev/null || true; } | sed 's/\x1b\[[0-9;]*m//g' | tail -n1 | tr -d '\r'; }
userdata="${SPICETIFY_USERDATA:-$(spice_value spicetify path userdata)}"
config="${SPICETIFY_CONFIG:-$(spice_value spicetify -c)}"

if [ -n "$userdata" ] && [ -d "$userdata/Extensions" ]; then
  real_base="$(realpath -e -- "$userdata")"
  real_ext="$(realpath -e -- "$userdata/Extensions")"
  case "$real_ext/" in
    "$real_base"/*)
      # rm on a symlink removes the link itself, never its target.
      rm -f -- "$real_ext/$EXT" "$real_ext/.noctalia-installed"
      ;;
    *)
      echo "Warning: Spicetify's Extensions folder resolves outside Spicetify's folder ($real_ext); not deleting anything there" >&2
      exit 1
      ;;
  esac
fi

if [ -f "$config" ]; then
  extensions="$(sed -n 's/^extensions[[:space:]]*=[[:space:]]*//p' "$config" | head -n1 | tr -d '[:space:]')"
  case "|$extensions|" in
    *"|$EXT|"*)
      spicetify config extensions "$EXT-" >/dev/null 2>&1 || { echo "Warning: could not remove $EXT from Spicetify's extensions" >&2; exit 1; }
      spicetify -q apply --no-restart >/dev/null 2>&1 || { echo "Warning: 'spicetify apply' failed; run it by hand to finish removing the extension" >&2; exit 1; }
      ;;
  esac
fi
exit 0
