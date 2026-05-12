#!/bin/bash

# Configuration
WALL_DIR="$HOME/Pictures/Walls" # Change this to your folder path
INTERVAL=1800                   # Time in seconds (e.g., 1800 = 30 mins)

# Ensure swww-daemon is running
if ! pgrep -x "awww-daemon" >/dev/null; then
  awww-daemon &
  sleep 1 # Give it a second to initialize
fi

while true; do
  # Pick a random file using 'shuf'
  # This is extremely fast even with thousands of files
  SELECTED_WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)

  # Apply the wallpaper with a smooth transition
  swww img "$SELECTED_WALL" --transition-type center --transition-step 90 --transition-fps 60

  sleep "$INTERVAL"
done
