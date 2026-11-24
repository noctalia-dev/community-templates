#!/usr/bin/env bash
# Wire retch's top-level `include_optional` to load themes/noctalia.toml
# without disturbing any existing required `include` or other optional files.
set -euo pipefail

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/retch/config.toml"

if [ ! -f "$config_file" ]; then
    echo "Error: retch config not found at $config_file -- run 'retch --write-config' first." >&2
    exit 1
fi

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
            return None, None
        line_start = s.rfind("\n", 0, i) + 1
        if s[i] == "[":
            return None, line_start
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
                return (line_start, val_start, val_end, j), None
        i = j


def analyze_array_inner(inner: str):
    i = 0
    n = len(inner)
    last_tok_end = None
    last_tok_is_comma = False
    first_indent = None
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
            end = skip_string(inner, i)
            if first_indent is None:
                ls = inner.rfind("\n", 0, i)
                if ls != -1:
                    first_indent = inner[ls + 1 : i]
            last_tok_end = end
            last_tok_is_comma = False
            i = end
            continue
        if c == ",":
            last_tok_end = i + 1
            last_tok_is_comma = True
            i += 1
            continue
        raise ValueError(f"unexpected character {c!r} in include_optional array")
    if first_indent is None or first_indent.strip(" \t") != "":
        first_indent = "    "
    return last_tok_end, last_tok_is_comma, first_indent


try:
    original = config_path.read_text(encoding="utf-8")
    doc = tomllib.loads(original)
except (OSError, UnicodeDecodeError, tomllib.TOMLDecodeError) as exc:
    print(f"Error: failed to parse {config_path}: {exc}", file=sys.stderr)
    sys.exit(2)

val = doc.get("include_optional")
if val is None:
    expected_val = TARGET
elif isinstance(val, str):
    if val == TARGET:
        sys.exit(0)
    expected_val = [val, TARGET]
elif isinstance(val, list) and all(isinstance(x, str) for x in val):
    if TARGET in val:
        sys.exit(0)
    expected_val = [*val, TARGET]
else:
    print(f"Error: top-level include_optional in {config_path} must be a string or array of strings.", file=sys.stderr)
    sys.exit(2)

eol = "\r\n" if "\r\n" in original else "\n"
assignment, first_table_pos = find_root_assignment(original, "include_optional")

if val is None:
    line = f'include_optional = "{TARGET}"{eol}'
    if first_table_pos is not None:
        before = original[:first_table_pos]
        after = original[first_table_pos:]
        if not before:
            new_text = line + eol + after
        else:
            sep = "" if before.endswith(("\n\n", "\r\n\r\n")) else eol
            new_text = before + sep + line + eol + after
    else:
        if not original:
            new_text = line
        else:
            tail_eol = "" if original.endswith("\n") else eol
            sep = "" if (original + tail_eol).endswith(("\n\n", "\r\n\r\n")) else eol
            new_text = original + tail_eol + sep + line
elif isinstance(val, str):
    assert assignment is not None
    _, val_start, val_end, _ = assignment
    raw_scalar = original[val_start:val_end]
    new_text = original[:val_start] + f'[{raw_scalar}, "{TARGET}"]' + original[val_end:]
else:
    assert assignment is not None
    _, val_start, val_end, _ = assignment
    inner = original[val_start + 1 : val_end - 1]
    last_tok_end, last_tok_is_comma, first_indent = analyze_array_inner(inner)
    if "\n" not in inner:
        if last_tok_end is None:
            new_arr = f'["{TARGET}"]'
        elif last_tok_is_comma:
            new_arr = f'[{inner[:last_tok_end]} "{TARGET}"]'
        else:
            new_arr = f'[{inner[:last_tok_end]}, "{TARGET}"]'
    else:
        if last_tok_end is not None and not last_tok_is_comma:
            inner_patched = inner[:last_tok_end] + "," + inner[last_tok_end:]
        else:
            inner_patched = inner
        before_last_nl, after_last_nl = inner_patched.rsplit("\n", 1)
        if after_last_nl.strip(" \t\r") == "":
            new_inner = f'{before_last_nl.rstrip(chr(13))}{eol}{first_indent}"{TARGET}",{eol}{after_last_nl}'
        else:
            new_inner = f'{inner_patched.rstrip(" " + chr(9) + chr(13))}{eol}{first_indent}"{TARGET}",{eol}'
        new_arr = f"[{new_inner}]"
    new_text = original[:val_start] + new_arr + original[val_end:]

expected_doc = copy.deepcopy(doc)
expected_doc["include_optional"] = expected_val

try:
    parsed = tomllib.loads(new_text)
except tomllib.TOMLDecodeError as exc:
    print(f"Error: refusing to write invalid TOML to {config_path}: {exc}", file=sys.stderr)
    sys.exit(2)

if parsed != expected_doc:
    print(f"Error: validation check failed for {config_path}; leaving live config untouched.", file=sys.stderr)
    sys.exit(2)

if new_text == original:
    sys.exit(0)

tmp_path.write_bytes(new_text.encode("utf-8"))
with tmp_path.open("rb") as fh:
    if tomllib.load(fh) != expected_doc:
        print(f"Error: staged config validation failed for {config_path}.", file=sys.stderr)
        sys.exit(2)

shutil.copyfile(tmp_path, config_path)
PY
