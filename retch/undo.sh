#!/usr/bin/env bash
# Revert apply.sh: remove "themes/noctalia.toml" from top-level `include_optional`
# in retch's config.toml and delete themes/noctalia.toml. Idempotent no-op if absent.
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/retch"
config_file="$config_dir/config.toml"
theme_file="$config_dir/themes/noctalia.toml"

if [ -f "$config_file" ]; then
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

        function clean_line_entries(line,   out, i, c, q, raw_start, token, in_comment, tail) {
            out = ""
            i = 1
            while (i <= length(line)) {
                c = substr(line, i, 1)
                if (in_comment) {
                    out = out substr(line, i)
                    break
                }
                if (c == "#") {
                    in_comment = 1
                    out = out substr(line, i)
                    break
                }
                if (c == "\"" || c == "\047") {
                    q = c
                    raw_start = i
                    token = ""
                    for (i++; i <= length(line); i++) {
                        c = substr(line, i, 1)
                        if (q == "\"" && c == "\\") {
                            token = token substr(line, i, 2)
                            i++
                            continue
                        }
                        if (c == q) break
                        token = token c
                    }
                    if (token == "themes/noctalia.toml") {
                        # Skip matching optional comma + spaces around removed item
                        if (sub(/,[[:space:]]*$/, "", out)) {
                            # removed preceding comma
                        } else {
                            tail = substr(line, i + 1)
                            if (match(tail, /^[[:space:]]*,[[:space:]]*/)) {
                                i += RLENGTH
                            }
                        }
                    } else {
                        out = out substr(line, raw_start, i - raw_start + 1)
                    }
                    i++
                    continue
                }
                out = out c
                i++
            }
            return out
        }

        function emit_cleaned_array(buf,   open, endp, inner, n, lines, k, cleaned, out, stripped) {
            open = find_syntax(buf, 1, "[")
            endp = find_syntax(buf, open + 1, "]")
            if (open == 0 || endp == 0 || endp < open) {
                printf "%s\n", buf
                return
            }
            inner = substr(buf, open + 1, endp - open - 1)
            if (!has_noctalia_entry(inner)) {
                printf "%s\n", buf
                return
            }

            if (index(buf, "\n") == 0) {
                cleaned = substr(buf, 1, open) clean_line_entries(inner) substr(buf, endp)
                open = find_syntax(cleaned, 1, "[")
                endp = find_syntax(cleaned, open + 1, "]")
                stripped = substr(cleaned, open + 1, endp - open - 1)
                gsub(/#[^\n]*/, "", stripped)
                gsub(/[[:space:],]/, "", stripped)
                if (stripped != "") {
                    printf "%s\n", cleaned
                }
                return
            }

            n = split(buf, lines, "\n")
            out = ""
            for (k = 1; k <= n; k++) {
                if (has_noctalia_entry(lines[k])) {
                    cleaned = clean_line_entries(lines[k])
                    if (cleaned ~ /^[[:space:]]*(#.*)?$/) {
                        continue
                    }
                    lines[k] = cleaned
                }
                out = (out == "" ? lines[k] : out "\n" lines[k])
            }
            open = find_syntax(out, 1, "[")
            endp = find_syntax(out, open + 1, "]")
            if (open > 0 && endp > open) {
                stripped = substr(out, open + 1, endp - open - 1)
                gsub(/#[^\n]*/, "", stripped)
                gsub(/[[:space:],]/, "", stripped)
                if (stripped != "") {
                    printf "%s\n", out
                }
            }
        }

        in_array {
            buf = buf "\n" $0
            if (find_syntax(buf, 1, "]") > 0) {
                emit_cleaned_array(buf)
                in_array = 0
                buf = ""
            }
            next
        }

        /^[[:space:]]*\[/ {
            seen_table = 1
            print
            next
        }

        !seen_table && /^[[:space:]]*include_optional[[:space:]]*=/ {
            eq = index($0, "=")
            rhs = substr($0, eq + 1)
            if (find_syntax(rhs, 1, "[") > 0) {
                if (find_syntax(rhs, 1, "]") > 0) {
                    emit_cleaned_array($0)
                } else {
                    in_array = 1
                    buf = $0
                }
                next
            }
            if (rhs ~ /^[[:space:]]*["\047]themes\/noctalia\.toml["\047][[:space:]]*(#.*)?$/) {
                next
            }
            print
            next
        }

        { print }
    ' "$config_file" >"$tmp_file"

    if ! cmp -s "$config_file" "$tmp_file"; then
        cat "$tmp_file" >"$config_file"
    fi
fi

rm -f -- "$theme_file"
