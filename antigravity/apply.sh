#!/usr/bin/env bash
set -euo pipefail

if [ -f ~/.gemini/config/config.json ]; then 
    jq -s '.[0].userSettings.customThemeSeedsDark = .[1].userSettings.customThemeSeedsDark | .[0].userSettings.customThemeSeedsLight = .[1].userSettings.customThemeSeedsLight | .[0]' ~/.gemini/config/config.json ~/.gemini/config/theme.json > ~/.gemini/config/config.json.tmp && mv ~/.gemini/config/config.json.tmp ~/.gemini/config/config.json; 
else 
    cp ~/.gemini/config/theme.json ~/.gemini/config/config.json; 
fi
