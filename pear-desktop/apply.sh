#!/bin/bash

JSON_FILE="$XDG_CONFIG_HOME/YouTube Music/config.json"
THEME_PATH="$XDG_CONFIG_HOME/YouTube Music/noctalia.css"

if [ ! -f "$JSON_FILE" ]; then
    exit 0
fi

jq --arg new_theme "$THEME_PATH" '.options.themes = [$new_theme]' "$JSON_FILE" > temp.json && mv temp.json "$JSON_FILE"
