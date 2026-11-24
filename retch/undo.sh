#!/usr/bin/env bash
# Revert apply.sh: remove "themes/noctalia.toml" from top-level `include_optional`
# in retch's config.toml and delete themes/noctalia.toml. Idempotent no-op if absent.
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/retch"
config_file="$config_dir/config.toml"
theme_file="$config_dir/themes/noctalia.toml"

if [ -f "$config_file" ]; then
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: python3 (3.11+) is required to update $config_file." >&2
        exit 1
    fi

    tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
    trap 'rm -f "$tmp_file"' EXIT

    python3 - "$config_file" "$tmp_file" <<'PY'
import copy
import shutil
import sys
from pathlib import Path

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("Error: Python 3.11+ (tomllib) is required to update retch config.toml.", file=sys.stderr)
        sys.exit(1)

TARGET = "themes/noctalia.toml"
config_path = Path(sys.argv[1])
tmp_path = Path(sys.argv[2])


def skip_string(s: str, i: int) -> int:
    n = len(s)
    if s.startswith('"""', i):
        j = i + 3
        while j < n:
            if s[j] == "\\":
                j += 2
                continue
            if s.startswith('"""', j):
                extra = 0
                while extra < 2 and j + 3 < n and s[j + 3] == '"':
                    j += 1
                    extra += 1
                return j + 3
            j += 1
        raise ValueError("unterminated multiline basic string")
    if s.startswith("'''", i):
        j = i + 3
        while j < n:
            if s.startswith("'''", j):
                extra = 0
                while extra < 2 and j + 3 < n and s[j + 3] == "'":
                    j += 1
                    extra += 1
                return j + 3
            j += 1
        raise ValueError("unterminated multiline literal string")
    q = s[i]
    j = i + 1
    while j < n:
        c = s[j]
        if q == '"' and c == "\\":
            j += 2
            continue
        if c == q:
            return j + 1
        if c in "\r\n":
            raise ValueError("unterminated string")
        j += 1
    raise ValueError("unterminated string")


def skip_ws_comments(s: str, i: int) -> int:
    n = len(s)
    while i < n:
        if s[i] in " \t\r\n":
            i += 1
        elif s[i] == "#":
            nl = s.find("\n", i)
            i = n if nl == -1 else nl + 1
        else:
            break
    return i


def skip_value(s: str, i: int) -> int:
    n = len(s)
    if i >= n:
        raise ValueError("missing value")
    if s[i] in ('"', "'"):
        return skip_string(s, i)
    if s[i] in "[{":
        depth = 0
        while i < n:
            c = s[i]
            if c in ('"', "'"):
                i = skip_string(s, i)
            elif c == "#":
                nl = s.find("\n", i)
                i = n if nl == -1 else nl + 1
            elif c in "[{":
                depth += 1
                i += 1
            elif c in "]}":
                depth -= 1
                i += 1
                if depth == 0:
                    return i
            else:
                i += 1
        raise ValueError("unterminated collection")
    start = i
    while i < n and s[i] not in "\r\n#":
        i += 1
    while i > start and s[i - 1] in " \t":
        i -= 1
    return i


def find_root_assignment(s: str, key: str):
    n = len(s)
    i = 0
    while True:
        i = skip_ws_comments(s, i)
        if i >= n:
            return None
        line_start = s.rfind("\n", 0, i) + 1
        if s[i] == "[":
            return None
        segments = []
        while True:
            while i < n and s[i] in " \t":
                i += 1
            if i < n and s[i] in ('"', "'"):
                end = skip_string(s, i)
                segments.append(s[i:end])
                i = end
            else:
                k_start = i
                while i < n and (s[i].isalnum() or s[i] in "_-"):
                    i += 1
                if i == k_start:
                    raise ValueError(f"unexpected token near offset {i}")
                segments.append(s[k_start:i])
            while i < n and s[i] in " \t":
                i += 1
            if i < n and s[i] == ".":
                i += 1
                continue
            break
        while i < n and s[i] in " \t":
            i += 1
        if i >= n or s[i] != "=":
            raise ValueError(f"expected '=' near offset {i}")
        i += 1
        while i < n and s[i] in " \t":
            i += 1
        val_start = i
        val_end = skip_value(s, val_start)
        j = val_end
        while j < n and s[j] in " \t":
            j += 1
        if j < n and s[j] == "#":
            nl = s.find("\n", j)
            j = n if nl == -1 else nl
        if j < n and s[j] == "\r":
            j += 1
        if j < n and s[j] == "\n":
            j += 1
        if len(segments) == 1:
            parsed_key = next(iter(tomllib.loads(f"{segments[0]} = 1")))
            if parsed_key == key:
                return line_start, val_start, val_end, j
        i = j


def tokenize_array(inner: str):
    items = []
    i = 0
    n = len(inner)
    while i < n:
        c = inner[i]
        if c in " \t\r\n":
            i += 1
            continue
        if c == "#":
            nl = inner.find("\n", i)
            i = n if nl == -1 else nl + 1
            continue
        if c in ('"', "'"):
            e = skip_string(inner, i)
            val = tomllib.loads(f"v = {inner[i:e]}")["v"]
            j = e
            comma_pos = None
            while j < n:
                if inner[j] in " \t\r\n":
                    j += 1
                elif inner[j] == "#":
                    nl = inner.find("\n", j)
                    j = n if nl == -1 else nl + 1
                elif inner[j] == ",":
                    comma_pos = j
                    break
                else:
                    break
            items.append((i, e, val, comma_pos))
            i = comma_pos + 1 if comma_pos is not None else e
            continue
        raise ValueError(f"unexpected character {c!r} in include_optional array")
    return items


def remove_statement(text: str, stmt_start: int, stmt_end: int) -> str:
    before = text[:stmt_start]
    after = text[stmt_end:]
    if before.endswith(("\n\n", "\r\n\r\n")):
        if after.startswith("\r\n"):
            after = after[2:]
        elif after.startswith("\n"):
            after = after[1:]
    return before + after


def remove_array_target(inner: str, target: str) -> str:
    while True:
        items = tokenize_array(inner)
        idx = next((k for k in range(len(items) - 1, -1, -1) if items[k][2] == target), None)
        if idx is None:
            return inner
        s, e, _, cpos = items[idx]
        line_start = inner.rfind("\n", 0, s) + 1
        nl_pos = inner.find("\n", e)
        line_end = len(inner) if nl_pos == -1 else nl_pos
        line_end_with_nl = len(inner) if nl_pos == -1 else nl_pos + 1

        only_item_on_line = False
        if "\n" in inner and inner[line_start:s].strip(" \t") == "":
            after_seg = inner[e:line_end].rstrip("\r")
            if cpos is not None and e <= cpos < line_end:
                before_c = inner[e:cpos].strip(" \t")
                after_c = inner[cpos + 1 : line_end].rstrip("\r").lstrip(" \t")
                only_item_on_line = before_c == "" and (after_c == "" or after_c.startswith("#"))
            else:
                trimmed = after_seg.lstrip(" \t")
                only_item_on_line = trimmed == "" or trimmed.startswith("#")

        if only_item_on_line:
            if cpos is not None and cpos >= line_end:
                inner = inner[:cpos] + inner[cpos + 1 :]
            if line_start == 0 and nl_pos != -1:
                inner = inner[:s] + inner[line_end_with_nl:]
                inner = inner.lstrip(" \t")
            else:
                inner = inner[:line_start] + inner[line_end_with_nl:]
        elif cpos is not None:
            if inner[e:cpos].strip(" \t") == "":
                del_end = cpos + 1
                while del_end < len(inner) and inner[del_end] in " \t":
                    del_end += 1
                inner = inner[:s] + inner[del_end:]
            else:
                inner = inner[:cpos] + inner[cpos + 1 :]
                inner = inner[:s] + inner[e:]
        elif idx > 0 and items[idx - 1][3] is not None and "\n" not in inner[items[idx - 1][3] : s]:
            prev_cpos = items[idx - 1][3]
            inner = inner[:prev_cpos] + inner[e:]
        else:
            inner = inner[:s] + inner[e:]


try:
    original = config_path.read_text(encoding="utf-8")
    doc = tomllib.loads(original)
except (OSError, UnicodeDecodeError, tomllib.TOMLDecodeError) as exc:
    print(f"Error: failed to parse {config_path}: {exc}", file=sys.stderr)
    sys.exit(2)

val = doc.get("include_optional")
if val is None:
    sys.exit(0)

assignment = find_root_assignment(original, "include_optional")
assert assignment is not None
stmt_start, val_start, val_end, stmt_end = assignment

expected_doc = copy.deepcopy(doc)
if isinstance(val, str):
    if val != TARGET:
        sys.exit(0)
    expected_doc.pop("include_optional", None)
    new_text = remove_statement(original, stmt_start, stmt_end)
elif isinstance(val, list) and all(isinstance(x, str) for x in val):
    if TARGET not in val:
        sys.exit(0)
    remaining = [x for x in val if x != TARGET]
    if not remaining:
        expected_doc.pop("include_optional", None)
        new_text = remove_statement(original, stmt_start, stmt_end)
    else:
        expected_doc["include_optional"] = remaining
        inner = original[val_start + 1 : val_end - 1]
        new_inner = remove_array_target(inner, TARGET)
        new_text = original[:val_start] + f"[{new_inner}]" + original[val_end:]
else:
    print(f"Error: top-level include_optional in {config_path} must be a string or array of strings.", file=sys.stderr)
    sys.exit(2)

try:
    parsed = tomllib.loads(new_text)
except tomllib.TOMLDecodeError as exc:
    print(f"Error: refusing to write invalid TOML to {config_path}: {exc}", file=sys.stderr)
    sys.exit(2)

if parsed != expected_doc:
    print(f"Error: validation check failed for {config_path}; leaving live config untouched.", file=sys.stderr)
    sys.exit(2)

if new_text != original:
    tmp_path.write_bytes(new_text.encode("utf-8"))
    with tmp_path.open("rb") as fh:
        if tomllib.load(fh) != expected_doc:
            print(f"Error: staged config validation failed for {config_path}.", file=sys.stderr)
            sys.exit(2)
    shutil.copyfile(tmp_path, config_path)
PY
fi

rm -f -- "$theme_file"
