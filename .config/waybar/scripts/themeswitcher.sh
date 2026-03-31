#!/bin/bash

# -----------------------------------------------------
# Configuration
# -----------------------------------------------------
THEME_DIR="$HOME/.config/waybar/themes"
CACHE_FILE="$HOME/.cache/.themestyle.sh"
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
LAUNCH_SCRIPT="$HOME/.config/waybar/launch.sh"

# -----------------------------------------------------
# Build Theme List
# -----------------------------------------------------
declare -A theme_map

# Loop through directories in themes folder
# We use a subshell to avoid changing directory for the main script
cd "$THEME_DIR" || exit
for dir in */; do
  dir=${dir%/}

  display_name="$dir"

  # Check for friendly name in config.sh
  if [ -f "$dir/config.sh" ]; then
    # Run in subshell to avoid polluting current environment
    display_name=$(
      source "$dir/config.sh"
      echo "$theme_name"
    )
  fi

  # Fallback if config.sh didn't produce a name or file logic failed
  if [ -z "$display_name" ]; then
    display_name="$dir"
  fi

  theme_map["$display_name"]="$dir"
done

# -----------------------------------------------------
# Show Rofi Menu
# -----------------------------------------------------
# Sort keys for consistent display
options=$(printf "%s\n" "${!theme_map[@]}" | sort)

choice=$(echo -e "$options" | rofi -dmenu -config "$ROFI_CONFIG" -no-show-icons -width 30 -p "Themes")

# -----------------------------------------------------
# Apply Selection
# -----------------------------------------------------
if [ -n "$choice" ] && [ -n "${theme_map[$choice]}" ]; then
  selected_dir="${theme_map[$choice]}"

  # Save the directory name to the cache file (Clean format)
  # Note: This writes just "ThemeName", not "/ThemeName;/Path"
  echo "$selected_dir" >"$CACHE_FILE"

  # Reload Waybar using the new launch script
  if [ -x "$LAUNCH_SCRIPT" ]; then
    "$LAUNCH_SCRIPT"
  else
    echo "Error: $LAUNCH_SCRIPT is not executable or found."
    # Fallback to simply trying to execute it
    bash "$LAUNCH_SCRIPT"
  fi
fi
