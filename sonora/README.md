# Sonora

Themes [Sonora](https://github.com/sonorahq/sonora) using the active Noctalia palette.

The template supports both native installations and the
`io.github.nolight132.sonora` Flatpak. It merges the generated appearance into
Sonora's existing `settings.json`, preserving accounts and other preferences.
Sonora watches that file and applies the new colors while running.

Launch Sonora once before enabling the template so its configuration directory
and `settings.json` exist. The merge hook requires `jq`.
