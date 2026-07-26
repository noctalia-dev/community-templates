#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


DEFAULT_ROOT = Path(__file__).resolve().parents[2]

# Shared allowlist so community entries group cleanly in the settings store
# instead of inventing a category of one. Includes the built-in set plus a few
# community-dense buckets (ai, chat, gaming).
CATEGORIES = {
    "ai",
    "audio",
    "browser",
    "chat",
    "compositor",
    "editor",
    "gaming",
    "launcher",
    "system",
    "terminal",
    "misc",
}

CATALOG_FIELDS = {"name", "category"}
ENTRY_FIELDS = {
    "input_path",
    "input_path_modes",
    "input_path_dynamic",
    "output_path",
    "output_path_dynamic",
    "pre_hook",
    "post_hook",
    "post_action",
    "requires_path",
    "compare_to",
    "colors_to_compare",
    "index",
    "enabled",
}

# Named built-ins run inside noctalia after the template write (not shell).
# Keep in sync with noctalia's template_engine post_action handlers.
POST_ACTIONS = {
    "firefox-theme",
}

# `{{ config_dir }}` in a hook or a dynamic command resolves to the template's own
# cached directory, so whatever follows it has to be a file this template ships.
CONFIG_DIR_RE = re.compile(r"\{\{\s*config_dir\s*\}\}/([^'\"\s]+)")


def is_non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and value.strip() != ""


class Validator:
    def __init__(self, root: Path) -> None:
        self.root = root.resolve()
        self.errors: list[str] = []

    def add_error(self, path: Path, message: str) -> None:
        try:
            where = path.relative_to(self.root).as_posix()
        except ValueError:
            where = path.as_posix()
        self.errors.append(f"{where}: {message}")

    def load(self, manifest_path: Path) -> dict[str, Any] | None:
        try:
            with manifest_path.open("rb") as handle:
                return tomllib.load(handle)
        except tomllib.TOMLDecodeError as error:
            self.add_error(manifest_path, f"invalid TOML: {error}")
            return None

    def validate_catalog(self, manifest_path: Path, manifest: dict[str, Any]) -> None:
        catalog = manifest.get("catalog")
        if not isinstance(catalog, dict) or not catalog:
            self.add_error(manifest_path, "missing [catalog.<id>] table")
            return

        if len(catalog) > 1:
            ids = ", ".join(sorted(catalog))
            self.add_error(manifest_path, f"expected exactly one [catalog.<id>] table, found: {ids}")

        folder = manifest_path.parent.name
        for template_id, info in catalog.items():
            if template_id != folder:
                self.add_error(manifest_path, f"[catalog.{template_id}] must be [catalog.{folder}], matching the directory")

            if not isinstance(info, dict):
                self.add_error(manifest_path, f"[catalog.{template_id}] must be a table")
                continue

            for field in sorted(set(info) - CATALOG_FIELDS):
                self.add_error(manifest_path, f"[catalog.{template_id}] has unknown field '{field}'")

            if not is_non_empty_string(info.get("name")):
                self.add_error(manifest_path, f"[catalog.{template_id}] name must be a non-empty string")

            category = info.get("category")
            if not is_non_empty_string(category):
                self.add_error(manifest_path, f"[catalog.{template_id}] category must be a non-empty string")
            elif category not in CATEGORIES:
                valid = ", ".join(sorted(CATEGORIES))
                self.add_error(manifest_path, f"[catalog.{template_id}] category '{category}' is not one of: {valid}")

    def validate_shipped_file(self, manifest_path: Path, context: str, field: str, value: str) -> None:
        """A path the template renders from, resolved inside the template's own folder."""
        candidate = Path(value)
        if candidate.is_absolute() or ".." in candidate.parts:
            self.add_error(manifest_path, f"{context}: {field} must stay inside the template directory")
            return
        if not (manifest_path.parent / candidate).is_file():
            self.add_error(manifest_path, f"{context}: {field} '{value}' does not exist in this directory")

    def validate_config_dir_refs(self, manifest_path: Path, context: str, field: str, command: str) -> None:
        for referenced in CONFIG_DIR_RE.findall(command):
            target = manifest_path.parent / referenced
            if not target.is_file():
                self.add_error(
                    manifest_path,
                    f"{context}: {field} runs '{{{{ config_dir }}}}/{referenced}', which this template does not ship "
                    f"(config_dir is the template's own directory, so files are referenced by name)",
                )
                continue
            if referenced.endswith(".sh"):
                first_line = target.read_text(encoding="utf-8", errors="replace").splitlines()[:1]
                if not first_line or not first_line[0].startswith("#!"):
                    self.add_error(manifest_path, f"{context}: '{referenced}' must start with a shebang")

    def validate_entry(self, manifest_path: Path, name: str, entry: Any) -> None:
        context = f"[templates.{name}]"
        if not isinstance(entry, dict):
            self.add_error(manifest_path, f"{context} must be a table")
            return

        for field in sorted(set(entry) - ENTRY_FIELDS):
            self.add_error(manifest_path, f"{context}: unknown field '{field}'")

        # Input: a file, a per-mode pair of files, or a command that prints one.
        has_input = False
        if "input_path" in entry:
            has_input = True
            if not is_non_empty_string(entry["input_path"]):
                self.add_error(manifest_path, f"{context}: input_path must be a non-empty string")
            else:
                self.validate_shipped_file(manifest_path, context, "input_path", entry["input_path"])

        if "input_path_modes" in entry:
            modes = entry["input_path_modes"]
            if not isinstance(modes, dict) or not {"dark", "light"} <= set(modes):
                self.add_error(manifest_path, f"{context}: input_path_modes needs both 'dark' and 'light'")
            else:
                has_input = True
                for mode in ("dark", "light"):
                    if not is_non_empty_string(modes[mode]):
                        self.add_error(manifest_path, f"{context}: input_path_modes.{mode} must be a non-empty string")
                    else:
                        self.validate_shipped_file(manifest_path, context, f"input_path_modes.{mode}", modes[mode])

        if "input_path_dynamic" in entry:
            if not is_non_empty_string(entry["input_path_dynamic"]):
                self.add_error(manifest_path, f"{context}: input_path_dynamic must be a non-empty string")
            else:
                has_input = True

        if not has_input:
            self.add_error(manifest_path, f"{context}: needs input_path, input_path_modes, or input_path_dynamic")

        # Output: a path, a list of paths, or a command that prints them.
        output_path = entry.get("output_path")
        if output_path is not None:
            values = output_path if isinstance(output_path, list) else [output_path]
            if not values:
                self.add_error(manifest_path, f"{context}: output_path must not be empty")
            for value in values:
                if not is_non_empty_string(value):
                    self.add_error(manifest_path, f"{context}: every output_path must be a non-empty string")

        if "output_path_dynamic" in entry and not is_non_empty_string(entry["output_path_dynamic"]):
            self.add_error(manifest_path, f"{context}: output_path_dynamic must be a non-empty string")

        if output_path is None and "output_path_dynamic" not in entry:
            self.add_error(manifest_path, f"{context}: needs output_path or output_path_dynamic")

        if "requires_path" in entry and not is_non_empty_string(entry["requires_path"]):
            self.add_error(manifest_path, f"{context}: requires_path must be a non-empty string")

        if "index" in entry and not isinstance(entry["index"], int):
            self.add_error(manifest_path, f"{context}: index must be an integer")

        if "enabled" in entry and not isinstance(entry["enabled"], bool):
            self.add_error(manifest_path, f"{context}: enabled must be a bool")

        post_action = entry.get("post_action")
        if post_action is not None:
            if not is_non_empty_string(post_action):
                self.add_error(manifest_path, f"{context}: post_action must be a non-empty string")
            elif post_action not in POST_ACTIONS:
                valid = ", ".join(sorted(POST_ACTIONS))
                self.add_error(manifest_path, f"{context}: post_action '{post_action}' is not one of: {valid}")
            else:
                # noctalia post_actions require exactly one concrete output path.
                outputs = entry.get("output_path")
                if outputs is None:
                    self.add_error(manifest_path, f"{context}: post_action requires output_path (not output_path_dynamic)")
                else:
                    values = outputs if isinstance(outputs, list) else [outputs]
                    if len(values) != 1:
                        self.add_error(manifest_path, f"{context}: post_action requires exactly one output_path")

        for field in ("pre_hook", "post_hook", "input_path_dynamic", "output_path_dynamic"):
            command = entry.get(field)
            if is_non_empty_string(command):
                self.validate_config_dir_refs(manifest_path, context, field, command)

    def validate_entries(self, manifest_path: Path, manifest: dict[str, Any]) -> None:
        templates = manifest.get("templates")
        if not isinstance(templates, dict) or not templates:
            self.add_error(manifest_path, "missing [templates.<entry>] table")
            return

        for name, entry in templates.items():
            self.validate_entry(manifest_path, name, entry)

    def validate_files(self, manifest_path: Path) -> None:
        for path in manifest_path.parent.rglob("*"):
            if path.is_symlink():
                rel = path.relative_to(self.root).as_posix()
                self.add_error(manifest_path, f"'{rel}' is a symlink; templates ship real files")

    def validate_template(self, manifest_path: Path) -> None:
        manifest = self.load(manifest_path)
        if manifest is None:
            return

        for field in sorted(set(manifest) - {"catalog", "templates"}):
            self.add_error(manifest_path, f"unknown top-level table '{field}'")

        self.validate_catalog(manifest_path, manifest)
        self.validate_entries(manifest_path, manifest)
        self.validate_files(manifest_path)

    def validate_layout(self) -> None:
        for manifest_path in self.root.rglob("template.toml"):
            if ".git" in manifest_path.parts:
                continue
            if len(manifest_path.relative_to(self.root).parts) != 2:
                self.add_error(manifest_path, "templates live at <template>/template.toml, one directory per template")

    def validate(self) -> int:
        self.validate_layout()
        for manifest_path in sorted(self.root.glob("*/template.toml")):
            self.validate_template(manifest_path)

        if self.errors:
            for error in self.errors:
                print(f"error: {error}", file=sys.stderr)
            return 1

        count = len(list(self.root.glob("*/template.toml")))
        print(f"Validated {count} template manifest(s).")
        return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate community Noctalia template manifests.")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="Repository root to validate.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    return Validator(args.root).validate()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
