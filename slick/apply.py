#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

THEME_KEY = "imported:noctalia"

config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
theme_path = config / "slick/slick/noctalia-theme.json"
settings_path = theme_path.with_name("settings.json")


# this is so a malformed settings.json (or one being written) doesn't break everything
# slick already does error handling, but just in case :P
def save(settings):
    tmp = settings_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(settings, indent=2))
    os.replace(tmp, settings_path)


def apply():
    if not settings_path.exists():
        sys.exit(f"slick: {settings_path} not found, open Slick once first")

    settings = json.loads(settings_path.read_text())
    themes = settings.setdefault("importedThemes", {})

    if THEME_KEY not in themes:
        settings["theme"] = THEME_KEY  # set theme to noctalia on first run

    themes[THEME_KEY] = json.loads(theme_path.read_text())

    save(settings)


def undo():
    theme_path.unlink(missing_ok=True)
    if not settings_path.exists():
        return

    settings = json.loads(settings_path.read_text())
    themes = settings.get("importedThemes", {})

    if THEME_KEY not in themes:
        return

    del themes[THEME_KEY]

    if not themes:
        del settings["importedThemes"]

    if settings.get("theme") == THEME_KEY:
        del settings["theme"]

    save(settings)


if sys.argv[1:] == ["undo"]:
    undo()
else:
    apply()
