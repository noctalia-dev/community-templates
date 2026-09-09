#!/usr/bin/env bash
# Post-hook for Konsole Noctalia template:
#
# 1. Restores user customizations (opacity, blur, wallpaper) saved by pre-apply.sh,
#    ensuring Description=Noctalia is always present so Konsole names the scheme properly.
#
# 2. Performs a live reload of running Konsole sessions via OSC 50 escape sequences,
#    evicting Konsole's in-memory ColorScheme cache and re-reading the updated colors
#    from disk without requiring an application restart.

set -euo pipefail

output="${XDG_DATA_HOME:-$HOME/.local/share}/konsole/noctalia.colorscheme"

if [ ! -f "$output" ]; then
    echo >&2 "konsole: rendered colorscheme not found at $output"
    exit 1
fi

# ── 1. Restore user settings from backup ──────────────────────────────
backup="${output}.general.bak"

if [ -f "$backup" ]; then
    # Ensure Description is present so the scheme never appears as "sin nombre"
    if ! grep -q '^Description=' "$backup"; then
        echo "Description=Noctalia" >> "$backup"
    fi

    # Remove the default [General] section rendered by the template
    sed -i --follow-symlinks '/^\[General\]/,$ d' "$output"

    # Append the user's saved [General] preferences and clean up backup
    cat "$backup" >> "$output"
    rm -f "$backup"
fi

# ── 2. Live-reload active Konsole sessions (OSC 50) ────────────────────
# Collect all active Konsole terminal pts devices (held directly by Konsole or child shells)
ttys=()

for konsole_pid in $(pgrep -x konsole 2>/dev/null || true); do
    # Check open file descriptors of the Konsole process
    for fd in /proc/"$konsole_pid"/fd/*; do
        target="$(readlink "$fd" 2>/dev/null || true)"
        if [[ "$target" =~ ^/dev/pts/[0-9]+$ ]]; then
            ttys+=("$target")
        fi
    done

    # Check controlling terminals of child processes (shells running in tabs/splits)
    for child in $(pgrep -P "$konsole_pid" 2>/dev/null || true); do
        child_tty="$(ps -o tty= -p "$child" 2>/dev/null | tr -d ' ' || true)"
        if [ -n "$child_tty" ] && [ "$child_tty" != "?" ]; then
            ttys+=("/dev/$child_tty")
        fi
    done
done

# If active terminals were found, cycle the scheme to trigger live reload
if [ ${#ttys[@]} -gt 0 ]; then
    unique_ttys=($(printf '%s\n' "${ttys[@]}" | sort -u))

    # Step A: Switch briefly to an alternate scheme name to release Konsole's
    # in-memory cached ColorScheme pointer (no physical file needed on disk)
    for tty_path in "${unique_ttys[@]}"; do
        if [ -w "$tty_path" ]; then
            printf '\033]50;ColorScheme=noctalia-transition\a' > "$tty_path" 2>/dev/null || true
        fi
    done

    # Step B: Brief pause for Konsole's event loop to release the cached scheme
    sleep 0.08

    # Step C: Switch back to noctalia, forcing Konsole to read updated colors from disk
    for tty_path in "${unique_ttys[@]}"; do
        if [ -w "$tty_path" ]; then
            printf '\033]50;ColorScheme=noctalia\a' > "$tty_path" 2>/dev/null || true
        fi
    done
fi
