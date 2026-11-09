#!/usr/bin/env bash
# Revert the COSMIC theme written by apply.py.
#
# The derived theme and Builder directories are fully owned by this template
# (apply.py rewrites every key), so removing them makes libcosmic fall back to
# COSMIC's built-in dark/light themes. A theme that was customized in
# cosmic-settings before this template was enabled is not restored.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
cosmic_dir="$config_home/cosmic"

for name in \
    com.system76.CosmicTheme.Dark \
    com.system76.CosmicTheme.Light \
    com.system76.CosmicTheme.Dark.Builder \
    com.system76.CosmicTheme.Light.Builder
do
    rm -rf -- "${cosmic_dir:?}/$name/v2"
done

# Mode and toolkit overrides revert to COSMIC's defaults when unset.
rm -f -- "$cosmic_dir/com.system76.CosmicTheme.Mode/v1/is_dark"
rm -f -- "$cosmic_dir/com.system76.CosmicTk/v1/apply_theme_global"

rmdir --ignore-fail-on-non-empty \
    "$cosmic_dir/com.system76.CosmicTheme.Mode/v1" \
    "$cosmic_dir/com.system76.CosmicTheme.Mode" \
    "$cosmic_dir/com.system76.CosmicTk/v1" 2>/dev/null || true

rm -f -- "$cache_home/noctalia/cosmic-palette"

echo "COSMIC theme removed; libcosmic apps use COSMIC's built-in theme again"
