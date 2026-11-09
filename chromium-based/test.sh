#!/usr/bin/env bash
set -euo pipefail

template_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=apply.sh
source "$template_dir/apply.sh"

scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export XDG_STATE_HOME="$scratch/state"
auth_log="$scratch/auth.log"
: > "$auth_log"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
installed=''
pkexec_available=1
auth_result=0
refresh_log="$scratch/refresh.log"
refresh_failure=''
: > "$refresh_log"

# Refresh is mocked too: validate the bounded, windowless invocation without
# launching a real browser, including launchers that fail or lack flag support.
# shellcheck disable=SC2329
timeout() {
    [[ $1 == --kill-after=1s && $2 == 5s ]] || fail 'refresh must have a bounded runtime'
    shift 2
    [[ $# == 3 && $2 == --refresh-platform-policy && $3 == --no-startup-window ]] \
        || fail 'refresh must request policy reload without a new window'
    printf '%s\n' "$1" >> "$refresh_log"
    [[ $1 != "$refresh_failure" ]]
}

# Mock discovery and authentication; no real browser, sudo, or polkit is used.
# Called by the sourced scripts.
# shellcheck disable=SC2329
command() {
    if [[ ${1:-} == -v ]]; then
        case $2 in
            pkexec) (( pkexec_available == 1 )) ;;
            *) [[ " $installed " == *" $2 "* ]] ;;
        esac
    else
        builtin command "$@"
    fi
}

[[ -z $(family_installed_ids) ]] || fail 'no browsers should produce no identifiers'
installed='helium chromium ungoogled-chromium brave brave-origin google-chrome-beta google-chrome-stable'
[[ $(family_installed_ids) == $'chromium\nchrome\nbrave' ]] || fail 'shared policy paths should be deduplicated'
installed='chromium-browser chrome-for-testing brave-browser-nightly'
[[ $(family_installed_ids) == $'chromium-browser\nchrome-for-testing\nbrave' ]] || fail 'alternate paths and channels should be detected'
if family_directory /tmp/arbitrary-path 2> /dev/null; then
    fail 'privileged destinations must use allowlisted identifiers'
fi
if family_validate_directory /tmp 2> /dev/null; then
    fail 'world-writable policy ancestors must be rejected'
fi

# Root helper operations are exercised under mktemp, as the current user. The
# test replaces only the directory ownership check and root directory creation.
family_registry() {
    printf 'chromium %s/chromium fake-chromium fake-helium\nbrave %s/brave fake-brave\n' "$scratch" "$scratch"
}
family_validate_directory() {
    local ancestor=$1
    [[ $ancestor == "$scratch/"* ]] || fail 'test attempted to access a real policy directory'
    while [[ $ancestor != "$scratch" ]]; do
        [[ ! -L $ancestor && ( ! -e $ancestor || -d $ancestor ) ]] || return 1
        ancestor=${ancestor%/*}
    done
}
# Called indirectly by family_manage in privileged.sh.
# shellcheck disable=SC2329
install() {
    if [[ $1 == -d ]]; then
        builtin command install -d -m 0755 -- "${@: -1}"
    else
        builtin command install "$@"
    fi
}

mock_helper() {
    [[ $1 == "$BASH" && $2 == "$template_dir/privileged.sh" ]] || fail 'unexpected privileged executable'
    shift 2
    if (( auth_result != 0 )); then
        return "$auth_result"
    fi
    local action=$1
    shift
    family_manage "$action" "$(id -u)" "$(id -g)" "$@"
}
# Called indirectly by family_elevate in apply.sh.
# shellcheck disable=SC2329
pkexec() {
    [[ $1 == --disable-internal-agent ]] || fail 'GUI flow must disable the text authentication agent'
    shift
    printf 'gui %s\n' "${*:3}" >> "$auth_log"
    printf 'Mock authentication output must not become a file path.\n'
    mock_helper "$@"
}
# shellcheck disable=SC2329
sudo() {
    printf 'terminal %s\n' "${*:3}" >> "$auth_log"
    mock_helper "$@"
}

[[ -z $(family_output) ]] || fail 'absent browsers should have no outputs'
[[ ! -s $auth_log && ! -e $XDG_STATE_HOME ]] || fail 'absent browsers should not prompt or create files'

installed='fake-chromium fake-helium'
auth_result=126
[[ -z $(family_output 2> "$scratch/warnings") ]] || fail 'cancelled setup should produce no outputs'
[[ ! -e $scratch/chromium ]] || fail 'cancelled authentication must not create policy directories'
[[ $(wc -l < "$auth_log") == 1 ]] || fail 'initial setup should request one authorization'
[[ -z $(family_output 2> /dev/null) ]] || fail 'cancelled setup should remain skipped'
[[ $(wc -l < "$auth_log") == 1 ]] || fail 'cancelled setup must not prompt on each theme change'
grep -q 'Manual fallback' "$scratch/warnings" || fail 'cancelled setup should explain the terminal fallback'

auth_result=0
pkexec_available=0
family_setup terminal 2> /dev/null
policy="$scratch/chromium/$family_policy_name"
[[ $(<"$policy") == '{}' ]] || fail 'manual setup should initialize an empty policy without polkit'
[[ $(stat -c %a "$policy") == 644 && $(stat -c %u "$policy") == "$(id -u)" ]] || fail 'policy permissions must belong to the desktop user'
grep -q '^terminal setup chromium$' "$auth_log" || fail 'manual setup must use sudo'
[[ $(family_output) == "$policy" ]] || fail 'a prepared policy should be an output without polkit'

printf '{ "BrowserThemeColor": "#0b1824" }\n' > "$policy"
inode=$(stat -c %i "$policy")
: > "$auth_log"
family_setup terminal
[[ $(family_output) == "$policy" && ! -s $auth_log ]] || fail 'normal palette changes should not elevate'
[[ $(stat -c %i "$policy") == "$inode" && $(<"$policy") == '{ "BrowserThemeColor": "#0b1824" }' ]] || fail 'repeated setup must preserve existing colors and inode'

pkexec_available=1
installed='fake-chromium fake-brave'
outputs=$(family_output 2> /dev/null)
[[ $outputs == "$policy"$'\n'"$scratch/brave/$family_policy_name" ]] || fail 'installing another browser should prepare only its new path'
[[ $(<"$auth_log") == 'gui setup brave' ]] || fail 'additional browsers should use one GUI authorization'
printf '{"HomepageLocation":"https://example.com"}\n' > "$scratch/chromium/other.json"

# Shared policy paths must still refresh every installed browser/channel.
installed='fake-chromium fake-helium fake-brave'
auth_before=$(<"$auth_log")
refresh_failure='fake-chromium'
family_refresh 2> "$scratch/refresh-warnings"
[[ $(<"$refresh_log") == $'fake-chromium\nfake-helium\nfake-brave' ]] || fail 'a failed refresh must not prevent other launchers from refreshing'
grep -q 'Reload policies' "$scratch/refresh-warnings" || fail 'failed refresh should explain the fallback'
[[ $(<"$auth_log") == "$auth_before" ]] || fail 'refresh must not request authentication'
[[ $(<"$policy") == '{ "BrowserThemeColor": "#0b1824" }' ]] || fail 'refresh must preserve the rendered policy'

refresh_failure=''
: > "$refresh_log"
mv "$scratch/brave/$family_policy_name" "$scratch/held-policy"
installed='fake-helium fake-brave'
family_refresh
[[ $(<"$refresh_log") == 'fake-helium' ]] || fail 'refresh must skip absent launchers and unprepared policy paths'
mv "$scratch/held-policy" "$scratch/brave/$family_policy_name"
: > "$refresh_log"
installed=''
family_refresh
[[ ! -s $refresh_log ]] || fail 'refresh without installed browsers must be a no-op'

# Removal cancellation leaves every policy unchanged and signals Noctalia to retry.
auth_result=126
if family_remove gui 2> /dev/null; then
    fail 'cancelled removal should remain pending'
fi
[[ -f $policy && $(<"$policy") == '{ "BrowserThemeColor": "#0b1824" }' ]] || fail 'cancelled removal must not alter colors'
auth_result=0
installed=''
family_remove gui 2> /dev/null
[[ ! -e $policy && ! -e $scratch/brave/$family_policy_name ]] || fail 'removal should include files for uninstalled browsers'
[[ -f $scratch/chromium/other.json && -d $scratch/chromium ]] || fail 'cleanup must preserve other policies and directories'
: > "$auth_log"
family_remove gui
[[ ! -s $auth_log ]] || fail 'repeated removal should not prompt'

# Successful first-use setup is automatic, and pkexec stdout must never become
# part of the dynamic output path list.
installed='fake-chromium'
[[ $(family_output 2> /dev/null) == "$policy" ]] || fail 'initial GUI setup should return the newly writable output'
[[ $(<"$auth_log") == 'gui setup chromium' ]] || fail 'first-use GUI setup should run once'
pkexec_available=0
if family_remove gui 2> /dev/null; then
    fail 'missing GUI agent/executable must leave removal pending'
fi
[[ -f $policy ]] || fail 'missing pkexec must preserve the policy'
family_remove terminal 2> /dev/null
[[ ! -e $policy ]] || fail 'manual sudo cleanup should work without polkit'

: > "$auth_log"
[[ -z $(family_output 2> /dev/null) ]] || fail 'missing pkexec should skip unprepared outputs'
[[ ! -e $policy ]] || fail 'missing pkexec must not prepare files'
family_setup terminal 2> /dev/null
[[ -f $policy ]] || fail 'manual setup must still work after automatic setup fails'

printf '{"BrowserThemeColor":"#ffffff","HomepageLocation":"https://example.com"}\n' > "$policy"
if family_manage setup "$(id -u)" "$(id -g)" chromium 2> /dev/null; then
    fail 'setup must refuse a file containing additional policies'
fi
if family_manage remove "$(id -u)" "$(id -g)" chromium 2> /dev/null; then
    fail 'privileged removal must refuse additional policy keys'
fi
family_remove terminal
grep -q HomepageLocation "$policy" || fail 'cleanup must preserve customized policy files'

rm "$policy"
printf '{}\n' > "$scratch/target.json"
ln -s "$scratch/target.json" "$policy"
for action in setup remove; do
    if family_manage "$action" "$(id -u)" "$(id -g)" chromium 2> /dev/null; then
        fail 'privileged operations must reject symlinked files'
    fi
done
[[ -L $policy && $(<"$scratch/target.json") == '{}' ]] || fail 'symlink targets must remain untouched'
rm "$policy"
rmdir "$scratch/brave"
ln -s "$scratch/chromium" "$scratch/brave"
if family_manage setup "$(id -u)" "$(id -g)" brave 2> /dev/null; then
    fail 'privileged operations must reject symlinked directories'
fi

printf '{}\n' > "$policy"
if family_manage remove "$(( $(id -u) + 1 ))" "$(id -g)" chromium 2> /dev/null; then
    fail 'privileged cleanup must refuse files owned by another user'
fi
chmod 0444 "$policy"
family_manage setup "$(id -u)" "$(id -g)" chromium 2> /dev/null
[[ $(stat -c %a "$policy") == 644 ]] || fail 'setup should repair write access only on a recognized caller-owned policy'

# Validate the real helper's identity guard without authorizing any root work.
if env -u PKEXEC_UID -u SUDO_UID "$BASH" "$template_dir/privileged.sh" setup invalid-browser 2> /dev/null; then
    fail 'the helper must reject unprivileged or unidentified callers'
fi
if family_manage setup "$(id -u)" "$(id -g)" chromium invalid-browser 2> /dev/null; then
    fail 'an unknown identifier must fail the complete preflight'
fi
[[ $(<"$policy") == '{}' ]] || fail 'failed preflight must preserve existing policy data'
chmod 0400 "$policy"
if family_manage setup "$(id -u)" "$(id -g)" chromium invalid-browser 2> /dev/null; then
    fail 'unknown identifiers must not allow earlier destinations to be modified'
fi
[[ $(stat -c %a "$policy") == 400 ]] || fail 'preflight must complete before permission changes'
chmod 0644 "$policy"
printf 'Chromium based tests passed.\n'
