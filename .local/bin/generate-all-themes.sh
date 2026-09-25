#!/bin/bash
set -e

source "$HOME/.config/quickshell/scripts/theme-sync-lock.sh"

echo "Regenerating all Material 3 Expressive themes from current matugen palette..."

notify-send -a "Theme Generator" "Initializing theme reloading..." "Regenerating from matugen palette"

# Run the 3 simple generators in parallel, then the theme generator separately
# (theme needs sassc/glib which may re-exec in nix-shell)
(
  cd ~/Projects/material3-expressive-icons && python3 generate.py
) &
(
  cd ~/Projects/material3-expressive-sddm && python3 generate.py
) &
(
  cd ~/Projects/material3-expressive-kvantum && python3 generate.py
) &
wait

echo "Running theme generator (may take a while)..."
cd ~/Projects/material3-expressive-theme && python3 generate.py

notify-send -a "Theme Generator" "Finished theme regeneration." "All theme outputs regenerated"

echo "All theme outputs regenerated successfully."
