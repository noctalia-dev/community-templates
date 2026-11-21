#!/usr/bin/env bash
# Wire retch's top-level `include_optional` to load themes/noctalia.toml
# without disturbing any existing required `include` or other optional files.
set -euo pipefail

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/retch/config.toml"

if [ ! -f "$config_file" ]; then
    echo "Error: retch config not found at $config_file -- run 'retch --write-config' first." >&2
    exit 1
fi

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

awk '
    function find_syntax(s, start, ch,   i, c, in_dq, in_sq, in_comment) {
        for (i = start; i <= length(s); i++) {
            c = substr(s, i, 1)
            if (c == "\n") { in_dq = 0; in_sq = 0; in_comment = 0; continue }
            if (in_comment) continue
            if (in_dq) {
                if (c == "\\") { i++; continue }
                if (c == "\"") in_dq = 0
                continue
            }
            if (in_sq) {
                if (c == "\047") in_sq = 0
                continue
            }
            if (c == "\"") { in_dq = 1; continue }
            if (c == "\047") { in_sq = 1; continue }
            if (c == "#") { in_comment = 1; continue }
            if (c == ch) return i
        }
        return 0
    }

    function has_noctalia_entry(s,   i, c, q, token, in_comment) {
        for (i = 1; i <= length(s); i++) {
            c = substr(s, i, 1)
            if (c == "\n") { in_comment = 0; continue }
            if (in_comment) continue
            if (c == "#") { in_comment = 1; continue }
            if (c == "\"" || c == "\047") {
                q = c
                token = ""
                for (i++; i <= length(s); i++) {
                    c = substr(s, i, 1)
                    if (q == "\"" && c == "\\") {
                        token = token substr(s, i, 2)
                        i++
                        continue
                    }
                    if (c == q) break
                    token = token c
                }
                if (token == "themes/noctalia.toml") return 1
            }
        }
        return 0
    }

    function extract_first_string(s, start,   i, c, q, raw_start) {
        for (i = start; i <= length(s); i++) {
            c = substr(s, i, 1)
            if (c == "\"" || c == "\047") {
                q = c
                raw_start = i
                for (i++; i <= length(s); i++) {
                    c = substr(s, i, 1)
                    if (q == "\"" && c == "\\") { i++; continue }
                    if (c == q) {
                        scalar_raw = substr(s, raw_start, i - raw_start + 1)
                        scalar_val = substr(s, raw_start + 1, i - raw_start - 1)
                        scalar_tail = substr(s, i + 1)
                        return 1
                    }
                }
                return 0
            }
        }
        return 0
    }

    function build_array(buf,   open, endp, head, inner, tail, strip_nl, indent, stripped) {
        open = find_syntax(buf, 1, "[")
        endp = find_syntax(buf, open + 1, "]")
        if (open == 0 || endp == 0 || endp < open) {
            print "Error: top-level include_optional must be a TOML string or array" > "/dev/stderr"
            exit 2
        }
        if (has_noctalia_entry(substr(buf, open + 1, endp - open - 1)))
            return buf

        head = substr(buf, 1, open)
        inner = substr(buf, open + 1, endp - open - 1)
        tail = substr(buf, endp)

        stripped = inner
        gsub(/[[:space:]]/, "", stripped)
        if (index(inner, "\n") > 0) {
            indent = "    "
            if (match(inner, /\n[ \t]*[^ \t\r\n#\]]/)) {
                indent = substr(inner, RSTART + 1, RLENGTH - 2)
            }
            if (stripped == "")
                return head "\n" indent "\"themes/noctalia.toml\",\n" tail
            sub(/[ \t\r\n]+$/, "", inner)
            if (inner !~ /,$/)
                inner = inner ","
            return head inner "\n" indent "\"themes/noctalia.toml\",\n" tail
        }

        if (stripped == "")
            return head "\"themes/noctalia.toml\"" tail
        sub(/[ \t]+$/, "", inner)
        if (inner ~ /,$/)
            return head inner " \"themes/noctalia.toml\"" tail
        return head inner ", \"themes/noctalia.toml\"" tail
    }

    {
        has_prev_line = 1
        prev_blank = ($0 ~ /^[[:space:]]*$/)
    }

    in_array {
        buf = buf "\n" $0
        if (find_syntax(buf, 1, "]") > 0) {
            printf "%s\n", build_array(buf)
            in_array = 0
            buf = ""
            done = 1
        }
        next
    }

    !seen_table && !done && /^[[:space:]]*\[/ {
        if (has_prev_line && !prev_blank_before) print ""
        print "include_optional = \"themes/noctalia.toml\""
        print ""
        done = 1
        seen_table = 1
        print
        prev_blank_before = prev_blank
        next
    }

    /^[[:space:]]*\[/ {
        seen_table = 1
        print
        prev_blank_before = prev_blank
        next
    }

    !seen_table && !done && /^[[:space:]]*include_optional[[:space:]]*=/ {
        eq = index($0, "=")
        rhs = substr($0, eq + 1)
        if (find_syntax(rhs, 1, "[") > 0) {
            if (find_syntax(rhs, 1, "]") > 0) {
                printf "%s\n", build_array($0)
                done = 1
            } else {
                in_array = 1
                buf = $0
            }
        } else if (extract_first_string($0, eq + 1)) {
            if (scalar_val == "themes/noctalia.toml") {
                print
            } else {
                print "include_optional = [" scalar_raw ", \"themes/noctalia.toml\"]" scalar_tail
            }
            done = 1
        } else {
            print "Error: unrecognized top-level include_optional value in " FILENAME > "/dev/stderr"
            exit 2
        }
        prev_blank_before = 0
        next
    }

    {
        print
        prev_blank_before = prev_blank
    }

    END {
        if (in_array) {
            print "Error: unterminated include_optional array" > "/dev/stderr"
            exit 2
        }
        if (!done) {
            if (has_prev_line && !prev_blank_before) print ""
            print "include_optional = \"themes/noctalia.toml\""
        }
    }
' "$config_file" >"$tmp_file"

if ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
fi
