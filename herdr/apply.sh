#!/usr/bin/env bash
# Splice the rendered Noctalia Herdr theme into config.toml and reload.
# If config.toml is a symlink, replace it with a regular file first.
set -euo pipefail
IFS=$'\n\t'

log() {
    printf '[%s] noctalia-herdr: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        log "ERROR: $1 not found"
        exit 1
    }
}

herdr_is_running() {
    pgrep -u "$(id -u)" -x herdr >/dev/null 2>&1
}

xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"

config_path="${xdg_config}/herdr/config.toml"
rendered_theme="${xdg_cache}/noctalia/herdr/theme.toml"
backup_dir="${xdg_data}/noctalia/herdr/backups"
config_original="${backup_dir}/config.toml.original"

usage() {
    cat <<'EOF'
Usage: apply.sh <dark|light>
       apply.sh backup
       apply.sh restore

  dark|light  Splice rendered [theme] into config.toml; reload if Herdr is up
  backup      Snapshot config.toml once; never overwrites
  restore     Copy the original snapshot back (Herdr must be stopped)
EOF
}

ensure_herdr_config() {
    if [ ! -f "$config_path" ]; then
        log "ERROR: Herdr config not found: $config_path"
        exit 1
    fi
}

# One-time snapshot so the pre-Noctalia theme can be restored.
backup_config() {
    ensure_herdr_config
    mkdir -p "$backup_dir"

    if [ -f "$config_original" ]; then
        log "Original config backup already exists: $config_original"
        return 0
    fi

    # Copy content, not a symlink, so the snapshot stays put if the live path is later replaced.
    cat -- "$config_path" >"$config_original"
    log "Saved original config to $config_original"
    if herdr_is_running; then
        log "NOTE: Herdr is running; this is an on-disk snapshot and may lag in-memory settings"
    fi
}

# Writing through a symlink would put palette hex in whatever the link targets.
# Replace that link with a regular file once, then splice host-locally.
replace_symlink_with_file() {
    [ -L "$config_path" ] || return 0

    local tmp
    tmp="$(mktemp "${config_path}.noctalia-tmp.XXXXXX")"
    cat -- "$config_path" >"$tmp"
    mv -f -- "$tmp" "$config_path"
    log "Replaced symlink at $config_path with a regular file"
}

splice_theme() {
    if [ ! -f "$rendered_theme" ]; then
        log "ERROR: rendered theme missing: $rendered_theme"
        log "Re-apply the Noctalia theme (or run: noctalia msg templates-apply)"
        exit 1
    fi
    require_cmd python3

    local rc=0
    python3 - "$config_path" "$rendered_theme" <<'PY' || rc=$?
import pathlib
import re
import sys
import tempfile
import tomllib

config_path = pathlib.Path(sys.argv[1])
rendered_path = pathlib.Path(sys.argv[2])
begin = "# noctalia-herdr-theme-begin"
end = "# noctalia-herdr-theme-end"

rendered = rendered_path.read_text()
try:
    parsed = tomllib.loads(rendered)
except tomllib.TOMLDecodeError as exc:
    raise SystemExit(f"rendered theme is not valid TOML: {exc}") from exc
if "theme" not in parsed:
    raise SystemExit("rendered theme missing [theme] table")

block = f"{begin}\n{rendered.rstrip()}\n{end}\n"
text = config_path.read_text()

if begin in text and end in text:
    pattern = re.compile(
        re.escape(begin) + r".*?" + re.escape(end) + r"\n?",
        re.DOTALL,
    )
    new_text = pattern.sub(block, text, count=1)
else:
    # Drop a pre-existing [theme] / [theme.custom] so we do not duplicate keys.
    lines = text.splitlines(keepends=True)
    kept: list[str] = []
    skipping = False
    table_re = re.compile(r"^\[([^\]]+)\]\s*$")
    for line in lines:
        match = table_re.match(line.strip("\n") if line.endswith("\n") else line)
        if match:
            name = match.group(1)
            skipping = name == "theme" or name.startswith("theme.")
        if not skipping:
            kept.append(line)
    body = "".join(kept)
    insert_at = None
    for idx, line in enumerate(kept):
        match = table_re.match(line.strip("\n") if line.endswith("\n") else line)
        if match:
            insert_at = idx
            break
    if insert_at is None:
        new_text = body.rstrip() + "\n\n" + block
    else:
        prefix = "".join(kept[:insert_at]).rstrip()
        suffix = "".join(kept[insert_at:])
        new_text = prefix + "\n\n" + block + "\n" + suffix.lstrip("\n")

if new_text == text:
    raise SystemExit(0)

tmp_fd, tmp_name = tempfile.mkstemp(
    prefix="config.toml.noctalia-",
    dir=str(config_path.parent),
)
tmp_path = pathlib.Path(tmp_name)
try:
    with open(tmp_fd, "w", encoding="utf-8") as handle:
        handle.write(new_text)
    tmp_path.replace(config_path)
except Exception:
    tmp_path.unlink(missing_ok=True)
    raise
raise SystemExit(2)
PY
    case "$rc" in
        0)
            log "theme block already matches rendered palette"
            ;;
        2)
            log "Wrote Noctalia [theme] block to $config_path"
            ;;
        *)
            log "ERROR: failed to splice Herdr theme"
            exit 1
            ;;
    esac
}

validate_and_reload() {
    if command -v herdr >/dev/null 2>&1; then
        if ! herdr config check; then
            log "ERROR: herdr config check failed after splice"
            exit 1
        fi
    else
        log "herdr binary not on PATH; skipped config check"
    fi

    if herdr_is_running; then
        if command -v herdr >/dev/null 2>&1; then
            herdr server reload-config
            log "Reloaded running Herdr server"
        else
            log "Herdr is running but herdr is not on PATH; reload with prefix+Shift+r"
        fi
    else
        log "Herdr is not running; theme applies on next start"
    fi
}

restore_config() {
    if [ ! -f "$config_original" ]; then
        log "ERROR: no original backup at $config_original"
        exit 1
    fi
    if herdr_is_running; then
        log "ERROR: Herdr is running; will not restore config.toml"
        exit 1
    fi
    ensure_herdr_config
    cat -- "$config_original" >"$config_path"
    log "Restored config from $config_original"
}

cmd="${1:-}"
case "$cmd" in
    backup)
        backup_config
        ;;
    restore)
        restore_config
        ;;
    dark | light)
        ensure_herdr_config
        backup_config
        replace_symlink_with_file
        splice_theme
        validate_and_reload
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
