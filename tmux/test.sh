#!/usr/bin/env bash
set -euo pipefail

template_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

export HOME="$test_dir/home"
export XDG_CONFIG_HOME="$HOME/.config"
config_file="$XDG_CONFIG_HOME/tmux/tmux.conf"
theme_file="$XDG_CONFIG_HOME/tmux/themes/noctalia.conf"
mkdir -p "$(dirname "$theme_file")" "$test_dir/bin"
touch "$theme_file"

printf '%s\n' \
  'source-file -q "/old/tmux/themes/noctalia.conf"' \
  'set -g status-position top' \
  'source-file "$HOME/.config/tmux/themes/noctalia.conf"' \
  'set -g @catppuccin_status_modules_right "date_time"' >"$config_file"

printf '#!/bin/sh\nexit 1\n' >"$test_dir/bin/tmux"
chmod +x "$test_dir/bin/tmux"
export PATH="$test_dir/bin:$PATH"

bash "$template_dir/apply.sh"
expected='source-file -q "$XDG_CONFIG_HOME/tmux/themes/noctalia.conf"'
[ "$(tail -n1 "$config_file")" = "$expected" ]
[ "$(grep -Fc 'tmux/themes/noctalia.conf' "$config_file")" -eq 1 ]

before="$(stat -c '%y' "$config_file")"
cp "$config_file" "$test_dir/after-first-apply"
bash "$template_dir/apply.sh"
cmp -s "$config_file" "$test_dir/after-first-apply"
[ "$(stat -c '%y' "$config_file")" = "$before" ]
[ "$(tail -n1 "$config_file")" = "$expected" ]
[ "$(grep -Fc 'tmux/themes/noctalia.conf' "$config_file")" -eq 1 ]

export HOME="$test_dir/missing-home"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME/tmux/themes"
touch "$XDG_CONFIG_HOME/tmux/themes/noctalia.conf"
if bash "$template_dir/apply.sh" 2>"$test_dir/error"; then
  echo "hook accepted a missing tmux config" >&2
  exit 1
fi
grep -Fq 'Error: tmux config file not found' "$test_dir/error"

echo "tmux apply hook verified"
