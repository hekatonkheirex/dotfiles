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
(
  cd ~/Projects/neo-brutalism-sddm && python3 generate.py
) &
(
  cd ~/Projects/neo-brutalism-kvantum && make install
) &
(
  cd ~/Projects/neo-brutalism-icons && make install
) &
wait

echo "Running theme generator (may take a while)..."
cd ~/Projects/material3-expressive-theme && python3 generate.py

# Neo Brutalism shares material3-expressive-theme's sass engine and mutates
# the same _colors-palette.scss/_colors.scss anchor files, so it must run
# sequentially after the M3 generator above, never in parallel with it.
echo "Running Neo Brutalism theme generator..."
cd ~/Projects/neo-brutalism-theme && python3 generate.py

notify-send -a "Theme Generator" "Finished theme regeneration." "All theme outputs regenerated"

echo "All theme outputs regenerated successfully."
