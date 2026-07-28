colors_file="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia-driftwm-colors"
driftwm_config="${XDG_CONFIG_HOME:-$HOME/.config}/driftwm/config.toml"

if [ ! -f "$colors_file" ]; then
    echo "noctalia-driftwm: colors file not found at $colors_file" >&2
    exit 1
fi

bg_line=
fg_line=
border_line=
border_focused_line=

while IFS= read -r line; do
    key="${line%% = *}"
    case "$key" in
        bg_color)              bg_line="$line" ;;
        fg_color)              fg_line="$line" ;;
        border_color)          border_line="$line" ;;
        border_color_focused)  border_focused_line="$line" ;;
    esac
done < "$colors_file"

sed_script=
for def_line in "$bg_line" "$fg_line" "$border_line" "$border_focused_line"; do
    [ -n "$def_line" ] || continue
    k="${def_line%% = *}"
    v="${def_line#* = }"
    sed_script="${sed_script}s|^$k = .*|$k = $v|;"
done

if [ -z "$sed_script" ]; then
    echo "noctalia-driftwm: no color values found in $colors_file" >&2
    exit 1
fi

if [ ! -f "$driftwm_config" ]; then
    echo "noctalia-driftwm: driftwm config not found at $driftwm_config" >&2
    exit 1
fi

sed -i "$sed_script" "$driftwm_config"
