#!/usr/bin/env bash
# Install the rendered Noctalia palette as a Vivaldi user theme.
#
# Vivaldi reads vivaldi.themes from Preferences at startup and keeps the file in
# memory while it runs, so Preferences is only edited when Vivaldi is stopped.
# The rendered settings.json is also packed as a ZIP for manual live import.
set -euo pipefail
IFS=$'\n\t'

theme_id="c9d015eb-e046-45f4-8e7a-d6118a07696b"
xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
xdg_state="${XDG_STATE_HOME:-$HOME/.local/state}"

rendered="${xdg_cache}/noctalia/vivaldi/settings.json"
data_dir="${xdg_data}/noctalia/vivaldi"
theme_zip="${data_dir}/Noctalia.zip"
backup_dir="${data_dir}/backups"
state_dir="${xdg_state}/noctalia/vivaldi"

log() {
    printf '[%s] noctalia-vivaldi: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

warn() {
    # Noctalia surfaces stderr messages that start with "Warning:" in Settings.
    printf 'Warning: %s\n' "$*" >&2
}

die() {
    printf 'noctalia-vivaldi: ERROR: %s\n' "$*" >&2
    exit 1
}

require_python() {
    command -v python3 >/dev/null 2>&1 || die "python3 is required to update Vivaldi preferences"
}

vivaldi_running() {
    # Fail closed: if pgrep is unavailable we cannot confirm Vivaldi is not running,
    # so assume it might be and abort the preference write.
    if ! command -v pgrep >/dev/null 2>&1; then
        warn "pgrep is not available; assuming Vivaldi may be running, so Preferences were not changed."
        return 0
    fi
    local name
    for name in vivaldi-bin vivaldi vivaldi-stable vivaldi-snapshot; do
        if pgrep -u "$(id -u)" -x "$name" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

# Native stable/snapshot installs and the Flatpak builds keep separate profiles.
vivaldi_roots() {
    local root
    for root in \
        "${xdg_config}/vivaldi" \
        "${xdg_config}/vivaldi-snapshot" \
        "${HOME}/.var/app/com.vivaldi.Vivaldi/config/vivaldi" \
        "${HOME}/.var/app/com.vivaldi.Vivaldi.Snapshot/config/vivaldi-snapshot"; do
        if [[ -d $root ]]; then
            printf '%s\n' "$root"
        fi
    done
}

profile_preferences() {
    local root=$1 prefs
    for prefs in "$root/Default/Preferences" "$root"/Profile\ */Preferences; do
        if [[ -f $prefs ]]; then
            printf '%s\n' "$prefs"
        fi
    done
}

# Vivaldi caches a user theme by id and version. Editing the colours of an
# already-active theme without changing its version is ignored on the next
# start, so bump the version on every render before installing or exporting.
bump_version() {
    local state_root=$1
    shift
    python3 - "$rendered" "$state_root" "$theme_id" "$@" <<'PY'
import json
import os
import sys
import tempfile
from pathlib import Path

rendered = Path(sys.argv[1])
state_root = Path(sys.argv[2])
theme_id = sys.argv[3]
profiles = [Path(item) for item in sys.argv[4:]]

counter_path = state_root / "version"
try:
    counter = int(counter_path.read_text(encoding="utf-8").strip())
except (FileNotFoundError, ValueError):
    counter = 0

existing = 0
for prefs_path in profiles:
    try:
        themes = json.loads(prefs_path.read_text(encoding="utf-8")).get("vivaldi", {}).get("themes", {})
        user = themes.get("user") if isinstance(themes, dict) else None
    except (OSError, json.JSONDecodeError):
        continue
    for item in user or []:
        if isinstance(item, dict) and item.get("id") == theme_id:
            version = item.get("version")
            if isinstance(version, int):
                existing = max(existing, version)

version = max(counter, existing) + 1
data = json.loads(rendered.read_text(encoding="utf-8"))
data["version"] = version
serialized = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
fd, temporary = tempfile.mkstemp(prefix=".settings.", dir=rendered.parent)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(serialized)
    os.replace(temporary, rendered)
except BaseException:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
    raise

state_root.mkdir(parents=True, exist_ok=True)
counter_path.write_text(f"{version}\n", encoding="utf-8")
PY
}

# Keep a copy of the rendered theme next to Vivaldi's data so it can be imported
# by hand while Vivaldi is running. Importing is a snapshot, not a live sync.
make_import_zip() {
    [[ -f $rendered ]] || die "rendered theme is missing: $rendered"
    python3 - "$rendered" "$theme_zip" <<'PY'
import json
import os
import sys
import tempfile
import zipfile
from pathlib import Path

rendered = Path(sys.argv[1])
destination = Path(sys.argv[2])
data = json.loads(rendered.read_text(encoding="utf-8"))

destination.parent.mkdir(parents=True, exist_ok=True)
fd, temporary = tempfile.mkstemp(prefix=".Noctalia.", suffix=".zip", dir=destination.parent)
os.close(fd)
try:
    with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("settings.json", json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    os.replace(temporary, destination)
except BaseException:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
    raise
PY
    log "wrote importable theme: $theme_zip"
}

install_profile() {
    local prefs=$1
    python3 - "$prefs" "$rendered" "$theme_id" "$backup_dir" "$state_dir" <<'PY'
import json
import os
import stat
import sys
import tempfile
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path

prefs_path = Path(sys.argv[1])
rendered_path = Path(sys.argv[2])
theme_id = sys.argv[3]
backup_root = Path(sys.argv[4])
state_root = Path(sys.argv[5])

prefs = json.loads(prefs_path.read_text(encoding="utf-8"))
theme = json.loads(rendered_path.read_text(encoding="utf-8"))
theme["id"] = theme_id

key = sha256(str(prefs_path.resolve()).encode("utf-8")).hexdigest()[:16]
state_path = state_root / f"{key}.json"
backup_path = backup_root / key / "Preferences.original"

vivaldi = prefs.setdefault("vivaldi", {})
if not isinstance(vivaldi, dict):
    raise SystemExit(f"unexpected vivaldi preference type in {prefs_path}")
themes = vivaldi.setdefault("themes", {})
if not isinstance(themes, dict):
    raise SystemExit(f"unexpected vivaldi.themes preference type in {prefs_path}")

user = themes.get("user")
if not isinstance(user, list):
    user = []

state = None
if state_path.is_file():
    try:
        state = json.loads(state_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        state = None
if not isinstance(state, dict):
    state = {
        "prefs": str(prefs_path),
        "original_current_present": "current" in themes,
        "original_current": themes.get("current"),
        "theme_existed": any(
            isinstance(item, dict) and item.get("id") == theme_id for item in user
        ),
        "installed_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    state_root.mkdir(parents=True, exist_ok=True)
    _fd, _tmp = tempfile.mkstemp(prefix=".state.", dir=state_root)
    with os.fdopen(_fd, "w", encoding="utf-8") as handle:
        json.dump(state, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    os.replace(_tmp, state_path)

replaced = False
for index, item in enumerate(user):
    if isinstance(item, dict) and item.get("id") == theme_id:
        user[index] = theme
        replaced = True
        break
if not replaced:
    user.append(theme)
themes["user"] = user
themes["current"] = theme_id

backup_path.parent.mkdir(parents=True, exist_ok=True)
if not backup_path.exists():
    backup_path.write_bytes(prefs_path.read_bytes())
    os.chmod(backup_path, 0o600)

mode = stat.S_IMODE(prefs_path.stat().st_mode)
serialized = json.dumps(prefs, separators=(",", ":"), ensure_ascii=False)
fd, temporary = tempfile.mkstemp(prefix=".Preferences.", dir=prefs_path.parent)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(serialized)
    os.chmod(temporary, mode)
    os.replace(temporary, prefs_path)
except BaseException:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
    raise

print(f"updated {prefs_path} ({'replaced' if replaced else 'added'} Noctalia theme)")
PY
}

apply_theme() {
    local mode=${1:-dark} root prefs
    require_python
    [[ -f $rendered ]] || die "rendered theme is missing: $rendered"

    mapfile -t roots < <(vivaldi_roots)
    (( ${#roots[@]} > 0 )) || die "no Vivaldi profile found (expected ~/.config/vivaldi or a Flatpak profile)"

    mapfile -t profiles < <(
        for root in "${roots[@]}"; do
            profile_preferences "$root"
        done
    )
    (( ${#profiles[@]} > 0 )) || die "no Vivaldi Preferences file found"

    bump_version "$state_dir" "${profiles[@]}"
    make_import_zip

    if vivaldi_running; then
        warn "Vivaldi is running, so its preferences were not changed. Quit Vivaldi and re-apply the Noctalia theme, or import $theme_zip from Settings > Themes > Library > Open Theme."
        return 0
    fi

    local count=0
    for prefs in "${profiles[@]}"; do
        install_profile "$prefs"
        count=$((count + 1))
    done

    log "installed Noctalia $mode theme in $count profile(s); start Vivaldi to see it"
}

undo_theme() {
    require_python

    mapfile -t roots < <(vivaldi_roots)
    (( ${#roots[@]} > 0 )) || return 0

    local installed=0 pending=0 prefs
    mapfile -t profiles < <(
        for root in "${roots[@]}"; do
            profile_preferences "$root"
        done
    )
    for prefs in "${profiles[@]}"; do
        if python3 - "$prefs" "$theme_id" <<'PY'
import json
import sys
from pathlib import Path

themes = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("vivaldi", {}).get("themes", {})
themes = themes if isinstance(themes, dict) else {}
user = themes.get("user")
ours = any(isinstance(item, dict) and item.get("id") == sys.argv[2] for item in user or [])
raise SystemExit(0 if ours or themes.get("current") == sys.argv[2] else 1)
PY
        then
            installed=1
            break
        fi
    done

    if (( installed == 0 )); then
        rm -f -- "$theme_zip"
        log "no Noctalia Vivaldi theme was installed"
        return 0
    fi

    if vivaldi_running; then
        warn "Vivaldi is running; quit it to let Noctalia restore the previous theme."
        return 1
    fi

    for prefs in "${profiles[@]}"; do
        if ! python3 - "$prefs" "$theme_id" "$state_dir" <<'PY'
import json
import os
import stat
import sys
import tempfile
from hashlib import sha256
from pathlib import Path

prefs_path = Path(sys.argv[1])
theme_id = sys.argv[2]
state_root = Path(sys.argv[3])
key = sha256(str(prefs_path.resolve()).encode("utf-8")).hexdigest()[:16]
state_path = state_root / f"{key}.json"

prefs = json.loads(prefs_path.read_text(encoding="utf-8"))
vivaldi = prefs.get("vivaldi")
if not isinstance(vivaldi, dict):
    raise SystemExit(0)
themes = vivaldi.get("themes")
if not isinstance(themes, dict):
    raise SystemExit(0)

user = themes.get("user")
if not isinstance(user, list):
    user = []
our_theme = any(isinstance(item, dict) and item.get("id") == theme_id for item in user)
if not our_theme and themes.get("current") != theme_id:
    # Nothing was installed in this profile.
    raise SystemExit(0)

state = {}
if state_path.is_file():
    try:
        state = json.loads(state_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        state = {}

themes["user"] = [
    item for item in user if not (isinstance(item, dict) and item.get("id") == theme_id)
]

if themes.get("current") == theme_id:
    system = themes.get("system")
    known = {
        item.get("id")
        for item in (system if isinstance(system, list) else []) + themes["user"]
        if isinstance(item, dict)
    }
    original = state.get("original_current")
    if state.get("original_current_present") and original != theme_id and original in known:
        themes["current"] = original
    elif "Vivaldi2" in known:
        themes["current"] = "Vivaldi2"
    elif "Vivaldi1" in known:
        themes["current"] = "Vivaldi1"
    elif known:
        themes["current"] = next(iter(known))
    else:
        themes.pop("current", None)

mode = stat.S_IMODE(prefs_path.stat().st_mode)
serialized = json.dumps(prefs, separators=(",", ":"), ensure_ascii=False)
fd, temporary = tempfile.mkstemp(prefix=".Preferences.", dir=prefs_path.parent)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(serialized)
    os.chmod(temporary, mode)
    os.replace(temporary, prefs_path)
except BaseException:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
    raise
state_path.unlink(missing_ok=True)
print(f"restored {prefs_path}")
PY
        then
            pending=$((pending + 1))
        fi
    done

    if (( pending > 0 )); then
        warn "Could not restore $pending Vivaldi profile(s). Preferences were left unchanged."
        return 1
    fi

    rm -f -- "$theme_zip"
    log "removed the Noctalia theme and restored the previous Vivaldi selection"
}

case "${1:-}" in
    dark | light)
        apply_theme "$1"
        ;;
    undo)
        undo_theme
        ;;
    -h | --help | help)
        printf 'Usage: %s <dark|light|undo>\n' "$0" >&2
        ;;
    *)
        printf 'Usage: %s <dark|light|undo>\n' "$0" >&2
        exit 1
        ;;
esac
