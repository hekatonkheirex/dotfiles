#!/bin/bash

# Directory containing themes
THEME_DIR="$HOME/.config/hypr/themes"
CONFIG_FILE="$HOME/.config/hypr/hyprModules/decorations.conf"

# List themes, strip extension
THEMES=$(ls "$THEME_DIR" | sed 's/\.conf$//')

# Show rofi menu
SELECTED=$(echo "$THEMES" | rofi -dmenu -p "Select Theme")

if [ -n "$SELECTED" ]; then
    # Construct the new source line preserving the style (using ~)
    NEW_THEME_ENTRY="source = ~/.config/hypr/themes/$SELECTED.conf"
    
    # Escape path for sed if necessary, but here we control the input (filenames) fairly well.
    # We assume filenames don't have special sed characters.
    
    # Replace the source line in decorations.conf
    # Matches 'source = ...themes/something.conf'
    sed -i "s|^source = .*themes/.*\.conf|$NEW_THEME_ENTRY|" "$CONFIG_FILE"
    
    # Reload Hyprland
    hyprctl reload
    
    # Optional: Send notification
    notify-send "Hyprland Theme" "Switched to $SELECTED"
fi
