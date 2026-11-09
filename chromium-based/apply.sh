#!/usr/bin/env bash
set -euo pipefail

family_template_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=privileged.sh
source "$family_template_dir/privileged.sh"

family_state_dir() {
    printf '%s/noctalia/chromium-based\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

family_installed_ids() {
    local identifier directory launchers_string launcher
    local -a launchers
    while read -r identifier directory launchers_string; do
        read -r -a launchers <<< "$launchers_string"
        for launcher in "${launchers[@]}"; do
            if command -v "$launcher" >/dev/null 2>&1; then
                printf '%s\n' "$identifier"
                break
            fi
        done
    done < <(family_registry)
}

family_policy_ready() {
    family_owned_policy "$1" "$(id -u)" && [[ -w $1 ]]
}

family_elevate() {
    local method=$1 action=$2
    shift 2
    case $method in
        gui)
            if ! command -v pkexec >/dev/null 2>&1; then
                printf 'Warning: pkexec is unavailable; use the manual Chromium based setup/remove command.\n' >&2
                return 1
            fi
            # No terminal agent: a missing GUI agent must not block the shell.
            pkexec --disable-internal-agent "$BASH" "$family_template_dir/privileged.sh" "$action" "$@" >&2
            ;;
        terminal)
            sudo "$BASH" "$family_template_dir/privileged.sh" "$action" "$@" >&2
            ;;
        *) return 1 ;;
    esac
}

family_setup() {
    local method=${1:-terminal} identifier directory file state marker
    local -a pending=()
    state=$(family_state_dir)
    marker="$state/setup-attempted"
    while IFS= read -r identifier; do
        directory=$(family_directory "$identifier") || return 1
        file="$directory/$family_policy_name"
        if family_policy_ready "$file"; then
            continue
        fi
        if [[ $method == gui && -f $marker ]] && grep -Fxq -- "$identifier" "$marker"; then
            continue
        fi
        pending+=("$identifier")
    done < <(family_installed_ids)

    if (( ${#pending[@]} == 0 )); then
        if [[ $method == terminal ]]; then
            rm -f -- "$marker"
        fi
        return 0
    fi
    if [[ $method == gui ]]; then
        # A cancelled/unavailable agent should not prompt on every palette change.
        # Disabling the template or using manual setup clears these attempts.
        mkdir -p -- "$state" || return 1
        printf '%s\n' "${pending[@]}" >> "$marker" || return 1
    fi
    if ! family_elevate "$method" setup "${pending[@]}"; then
        printf 'Warning: Chromium based setup was not completed; unprepared browsers are skipped. Manual fallback: bash "%s/apply.sh" setup\n' "$family_template_dir" >&2
        return 1
    fi
    if [[ $method == terminal ]]; then
        rm -f -- "$marker"
    fi
}

family_output() {
    local identifier directory file
    family_setup gui || true
    while IFS= read -r identifier; do
        directory=$(family_directory "$identifier") || return 1
        file="$directory/$family_policy_name"
        if family_policy_ready "$file"; then
            printf '%s\n' "$file"
        fi
    done < <(family_installed_ids)
}

family_refresh() {
    local identifier directory launchers_string launcher
    local -a launchers
    while read -r identifier directory launchers_string; do
        family_policy_ready "$directory/$family_policy_name" || continue
        read -r -a launchers <<< "$launchers_string"
        # Channels can share a policy directory but run separate instances.
        for launcher in "${launchers[@]}"; do
            command -v "$launcher" >/dev/null 2>&1 || continue
            # Some builds remain alive without an existing browser instance.
            # Bound the refresh request so it cannot leave a background browser.
            if ! timeout --kill-after=1s 5s "$launcher" \
                --refresh-platform-policy --no-startup-window >/dev/null 2>&1; then
                printf 'Warning: could not refresh %s policies; use Reload policies or restart the browser.\n' "$launcher" >&2
            fi
        done
    done < <(family_registry)
}

family_remove() {
    local method=${1:-gui} identifier directory launchers file state
    local -a pending=()
    # Include recognized files even after the browser has been uninstalled.
    while read -r identifier directory launchers; do
        file="$directory/$family_policy_name"
        if family_owned_policy "$file" "$(id -u)"; then
            pending+=("$identifier")
        fi
    done < <(family_registry)
    if (( ${#pending[@]} > 0 )); then
        if ! family_elevate "$method" remove "${pending[@]}"; then
            printf 'Warning: Chromium based removal was not completed; the policy remains active. Manual fallback: bash "%s/apply.sh" remove\n' "$family_template_dir" >&2
            return 1
        fi
    fi
    state=$(family_state_dir)
    rm -f -- "$state/setup-attempted"
}

family_main() {
    if (( EUID == 0 )); then
        printf 'Run apply.sh as your desktop user; it requests authentication when needed.\n' >&2
        return 1
    fi
    local identifier
    case ${1:-} in
        list)
            while IFS= read -r identifier; do
                family_directory "$identifier"
            done < <(family_installed_ids)
            ;;
        setup) family_setup terminal ;;
        output) family_output ;;
        refresh) family_refresh ;;
        undo) family_remove gui ;;
        remove) family_remove terminal ;;
        *) printf 'Usage: bash %s {list|setup|output|refresh|undo|remove}\n' "$0" >&2; return 1 ;;
    esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    family_main "$@"
fi
