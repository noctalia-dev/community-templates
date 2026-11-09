#!/usr/bin/env bash
set -euo pipefail

family_policy_name="noctalia-color.json"

# Shared by the user hook and privileged helper. Only these identifiers and
# destinations are accepted; callers cannot pass arbitrary filesystem paths.
family_registry() {
    cat <<'BROWSERS'
chromium /etc/chromium/policies/managed chromium ungoogled-chromium ungoogled-chromium-browser helium helium-browser
chromium-browser /etc/chromium-browser/policies/managed chromium-browser
chrome /etc/opt/chrome/policies/managed google-chrome google-chrome-stable google-chrome-beta google-chrome-unstable
chrome-for-testing /etc/opt/chrome_for_testing/policies/managed google-chrome-for-testing chrome-for-testing
brave /etc/brave/policies/managed brave brave-browser brave-beta brave-browser-beta brave-nightly brave-browser-nightly brave-origin brave-origin-browser
BROWSERS
}

family_directory() {
    local identifier directory _launchers
    while read -r identifier directory _launchers; do
        if [[ $identifier == "$1" ]]; then
            printf '%s\n' "$directory"
            return 0
        fi
    done < <(family_registry)
    printf 'Unknown Chromium based browser identifier: %s\n' "$1" >&2
    return 1
}

family_content_is_ours() {
    local contents
    local pattern='^[[:space:]]*\{[[:space:]]*("BrowserThemeColor"[[:space:]]*:[[:space:]]*"#[[:xdigit:]]{6}"[[:space:]]*)?\}[[:space:]]*$'
    contents=$(<"$1")
    [[ $contents =~ $pattern ]]
}

family_owned_policy() {
    [[ -f $1 && ! -L $1 && -r $1 ]] \
        && [[ $(stat -c %u -- "$1") == "$2" ]] \
        && family_content_is_ours "$1"
}

family_validate_directory() {
    local ancestor=$1 mode
    while [[ $ancestor != / ]]; do
        if [[ -L $ancestor || ( -e $ancestor && ! -d $ancestor ) ]]; then
            printf 'Refusing a symlink or non-directory in policy path: %s\n' "$ancestor" >&2
            return 1
        fi
        if [[ -d $ancestor ]]; then
            mode=$(stat -c %a -- "$ancestor") || return 1
            if [[ $(stat -c %u -- "$ancestor") != 0 ]] || (( (8#$mode & 0022) != 0 )); then
                printf 'Refusing a policy directory writable by non-root users: %s\n' "$ancestor" >&2
                return 1
            fi
        fi
        ancestor=${ancestor%/*}
        [[ -n $ancestor ]] || ancestor=/
    done
}

family_manage() {
    local action=$1 owner_uid=$2 owner_gid=$3
    shift 3
    local identifier directory file
    local -a directories=()
    case $action in
        setup|remove) ;;
        *) printf 'Unknown policy operation: %s\n' "$action" >&2; return 1 ;;
    esac

    # Validate every destination before changing any of them. Existing policy
    # files must belong to the caller and contain only this template's data.
    for identifier in "$@"; do
        directory=$(family_directory "$identifier") || return 1
        family_validate_directory "$directory" || return 1
        file="$directory/$family_policy_name"
        if [[ -e $file || -L $file ]]; then
            if ! family_owned_policy "$file" "$owner_uid"; then
                printf 'Refusing to replace, take ownership of, or remove another policy: %s\n' "$file" >&2
                return 1
            fi
        fi
        directories+=("$directory")
    done

    for directory in "${directories[@]}"; do
        file="$directory/$family_policy_name"
        case $action in
            setup)
                if [[ ! -d $directory ]]; then
                    install -d -o 0 -g 0 -m 0755 -- "$directory" || return 1
                fi
                if [[ ! -e $file ]]; then
                    install -o "$owner_uid" -g "$owner_gid" -m 0644 /dev/stdin "$file" <<< '{}' || return 1
                else
                    # Restore write access only on a recognized, caller-owned file.
                    chmod 0644 -- "$file" || return 1
                fi
                printf 'Prepared: %s\n' "$file" >&2
                ;;
            remove)
                if [[ -e $file ]]; then
                    rm -- "$file" || return 1
                    printf 'Removed: %s\n' "$file" >&2
                fi
                ;;
        esac
    done
}

family_privileged_main() {
    if (( EUID != 0 )); then
        printf 'This helper must be invoked through pkexec or sudo.\n' >&2
        return 1
    fi
    local owner_uid=${PKEXEC_UID:-${SUDO_UID:-}} owner_gid
    if [[ ! $owner_uid =~ ^[1-9][0-9]*$ ]]; then
        printf 'Cannot determine the desktop user from PKEXEC_UID or SUDO_UID.\n' >&2
        return 1
    fi
    owner_gid=$(id -g -- "$owner_uid") || return 1
    if (( $# < 2 )); then
        printf 'Usage: privileged.sh {setup|remove} browser-id [...]\n' >&2
        return 1
    fi
    local action=$1
    shift
    family_manage "$action" "$owner_uid" "$owner_gid" "$@"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    # Use system tools, including NixOS's system profile, after elevation.
    export PATH=/run/current-system/sw/bin:/usr/sbin:/usr/bin:/sbin:/bin
    family_privileged_main "$@"
fi
