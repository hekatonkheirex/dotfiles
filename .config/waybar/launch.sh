#!/bin/bash

# ----------------------------------------------------- 
# Quit all running waybar instances
# ----------------------------------------------------- 
killall waybar

# ----------------------------------------------------- 
# Constants
# ----------------------------------------------------- 
CACHE_FILE="$HOME/.cache/.themestyle.sh"
THEME_DIR="$HOME/.config/waybar/themes"
DEFAULT_THEME="Catppuccin-Mocha-Vertical"

# ----------------------------------------------------- 
# Read current theme
# ----------------------------------------------------- 
if [ -f "$CACHE_FILE" ]; then
    THEME=$(cat "$CACHE_FILE")
else
    THEME="$DEFAULT_THEME"
fi

# ----------------------------------------------------- 
# Migration/Sanitization: Handle old format (/Theme;Path)
# ----------------------------------------------------- 
# This converts "/ThemeName;/Path" or "/ThemeName" to just "ThemeName"
# It ensures compatibility if the old switcher was used.
THEME=$(echo "$THEME" | cut -d';' -f1 | sed 's|^/||')

# ----------------------------------------------------- 
# Validate theme existence
# ----------------------------------------------------- 
if [ ! -d "$THEME_DIR/$THEME" ]; then
    echo "Theme '$THEME' not found. Reverting to default."
    THEME="$DEFAULT_THEME"
fi

# ----------------------------------------------------- 
# Save valid, clean theme name
# ----------------------------------------------------- 
echo "$THEME" > "$CACHE_FILE"

# ----------------------------------------------------- 
# Select config file
# ----------------------------------------------------- 
CONFIG_FILE="config.jsonc"

# ----------------------------------------------------- 
# Launch Waybar
# ----------------------------------------------------- 
echo "Loading waybar with config: $THEME_DIR/$THEME/$CONFIG_FILE"
waybar -c "$THEME_DIR/$THEME/$CONFIG_FILE" -s "$THEME_DIR/$THEME/style.css" &
