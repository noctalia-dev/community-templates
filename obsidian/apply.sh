#!/usr/bin/bash
set -euo pipefail

# Discover Obsidian vaults by finding .obsidian directories.
# Creates the snippets/ folder if it doesn't exist and enables the snippet
# in each vault's appearance.json.

snippet_name="noctalia"

find_vaults() {
python3 -c "
import json
try:
    with open('$HOME/.config/obsidian/obsidian.json') as f:
        for name, vault in json.load(f)['vaults'].items():
            print(vault['path'] + '/.obsidian')
except FileNotFoundError:
    pass
"
}

case "${1:-}" in
    output)
        # Called by noctalia to determine output paths.
        # Print one path per line for each discovered vault.
        find_vaults | while read -r obsidian_dir; do
            snippets_dir="$obsidian_dir/snippets"
            mkdir -p "$snippets_dir"
            echo "$snippets_dir/$snippet_name.css"
        done
        ;;
    apply)
        # Called after rendering. Enable the snippet in each vault's appearance.json.
        find_vaults | while read -r obsidian_dir; do
            appearance_file="$obsidian_dir/appearance.json"

            if [ ! -f "$appearance_file" ]; then
                printf '{\n  "enabledCssSnippets": ["%s"]\n}\n' "$snippet_name" > "$appearance_file"
                continue
            fi

            # Add noctalia to enabledCssSnippets if not already present
            python3 -c "
import json, sys

with open('$appearance_file') as f:
    data = json.load(f)

snippets = data.get('enabledCssSnippets', [])
if '$snippet_name' not in snippets:
    snippets.append('$snippet_name')
    data['enabledCssSnippets'] = snippets
    with open('$appearance_file', 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
" 2>/dev/null || true
        done
        ;;
    *)
        echo "Usage: $0 {output|apply}" >&2
        exit 1
        ;;
esac
