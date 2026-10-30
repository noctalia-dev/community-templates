#!/usr/bin/env bash
# noctalia-hermes-sync — write the Noctalia-rendered skin into every Hermes
# profile and activate it.
#
# Modeled on the hermes-themes-pack (Omarchy edition):
#   hooks/theme-set  -> the profile iteration and the opt-out rule
#   installer.py     -> atomic_write, guarded(), run_hermes(), select()
#
# Noctalia renders `hermes-skin.yaml` into a staging file, then runs this as
# the template's post_hook. Every Hermes home (the root home plus each
# profile) gets the skin written into it and the skin selected.
#
# Opt-out: a home with the marker file `.noctalia-hermes-sync-off` is skipped.
# Everything else is themed — enabling the template is the consent.
#
# Performance: this runs on EVERY palette change, so it does as little as
# possible. The Hermes CLI costs seconds to start, so it is only invoked
# when the active skin actually has to change — a palette change alone does
# not need it, because the gateway's watcher repaints on the skin file's
# mtime. The skin file itself is only rewritten when its content differs.

set -u

ROOT="${HERMES_ROOT:-$HOME/.hermes}"
SKIN_NAME="noctalia"
# Must match `output_path` in template.toml — the file Noctalia renders.
# An absolute path: Noctalia does not expand $XDG_STATE_HOME in a user
# template's output_path, and the hook must read the exact same file.
STAGING="${NOCTALIA_HERMES_STAGING:-${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/hermes/hermes-skin.yaml}"
TIMEOUT="${NOCTALIA_HERMES_TIMEOUT:-90}"

# ── worker mode ─────────────────────────────────────────────────────────────
# The parent spawns one child per Hermes home so they run in parallel.
if [[ "${1:-}" == "--sync-one" ]]; then
  _home="${2:?home required}"
  _staging="${3:?staging required}"
  _skin="${4:?skin name required}"
  _hermes="${5:?hermes binary required}"
  _marker=".noctalia-hermes-sync-off"
  _target="$_home/skins/$_skin.yaml"

  # Opt-out: a home with the marker is skipped.
  if [[ -f "$_home/$_marker" ]]; then
    exit 0
  fi

  # Never follow a symlink out of the chosen profile home.
  if [[ -L "$_target" ]]; then
    echo "noctalia-hermes-sync: refusing symlinked target $_target" >&2
    exit 0
  fi
  case "$_target" in
    "$_home"/*) ;;
    *)
      echo "noctalia-hermes-sync: refusing escaped target $_target" >&2
      exit 0
      ;;
  esac

  # Only rewrite the skin when its content actually changed. Writing an
  # identical file would still bump the mtime, and the gateway's watcher
  # would repaint every surface for nothing.
  if [[ -f "$_target" ]] && cmp -s "$_staging" "$_target"; then
    _unchanged=1
  else
    _unchanged=0
  fi

  # Only call the Hermes CLI when the active skin is not already ours.
  # `hermes config set` starts a Python process (seconds) and rewrites the
  # config even when the value is unchanged.
  _active="$(awk '
    /^display:[[:space:]]*$/ { in_display = 1; next }
    /^[^[:space:]]/ { in_display = 0 }
    in_display && /^[[:space:]]+skin:[[:space:]]*/ {
      sub(/^[[:space:]]*skin:[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  ' "$_home/config.yaml" 2>/dev/null)"

  if [[ "$_active" == "$_skin" ]]; then
    _already=1
  else
    _already=0
  fi

  # Nothing to do: the skin is current and already selected.
  if [[ "$_unchanged" == "1" && "$_already" == "1" ]]; then
    exit 0
  fi

  if [[ "$_unchanged" == "0" ]]; then
    # Atomic write: a temp file in the same directory, then a rename. An
    # interrupted run leaves the previous skin intact instead of a truncated
    # YAML.
    _dir="$(dirname "$_target")"
    mkdir -p "$_dir" || exit 1
    _tmp="$(mktemp "$_dir/.noctalia-hermes-sync.XXXXXX")" || exit 1
    if cat "$_staging" > "$_tmp"; then
      chmod 644 "$_tmp"
      mv -f "$_tmp" "$_target"
    else
      rm -f "$_tmp"
      exit 1
    fi
  fi

  if [[ "$_already" == "0" ]]; then
    HERMES_HOME="$_home" "$_hermes" config set display.skin "$_skin" >/dev/null 2>&1
    exit $?
  fi

  exit 0
fi

# ── parent mode ─────────────────────────────────────────────────────────────

# The desktop app only paints a backend skin whose name is not a desktop
# built-in (see BUILTIN_THEMES / RETIRED_SKINS in the Hermes desktop app).
case "$SKIN_NAME" in
  nous | github | catppuccin | everforest | solarized | nous-alt | classic | \
  midnight | ember | mono | slate | cyberpunk | nous-light | default | gold)
    echo "noctalia-hermes-sync: '$SKIN_NAME' shadows a desktop built-in; refusing" >&2
    exit 1
    ;;
esac

if [[ ! -r "$STAGING" ]]; then
  # Nothing rendered yet (the hook can fire before the first render). Not an
  # error: the hook runs on every palette change.
  exit 0
fi

# The Hermes CLI writes config through its own safe writer. `hermes config set`
# never hand-edits config.yaml, so the live gateway keeps working.
hermes_bin=""
for candidate in \
  "$(command -v hermes 2>/dev/null || true)" \
  "$HOME/.local/bin/hermes" \
  "$HOME/.hermes/hermes-agent/.hermes/bin/hermes"; do
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    hermes_bin="$candidate"
    break
  fi
done

if [[ -z "$hermes_bin" ]]; then
  echo "noctalia-hermes-sync: hermes CLI not found on PATH" >&2
  exit 1
fi

# Homes run in parallel so one slow profile cannot hold up the rest; each is
# bounded by a timeout so a hung CLI cannot wedge the hook.
pids=()
for home in "$ROOT" "$ROOT"/profiles/*; do
  [[ -d "$home" ]] || continue
  # Hermes only recognises a directory as a profile when it carries an
  # identity file; skip stray directories.
  [[ -f "$home/config.yaml" ]] || continue
  timeout "$TIMEOUT" bash "$0" --sync-one "$home" "$STAGING" "$SKIN_NAME" "$hermes_bin" &
  pids+=("$!")
done

status=0
for pid in "${pids[@]:-}"; do
  [[ -n "$pid" ]] || continue
  wait "$pid" || status=1
done

exit "$status"
