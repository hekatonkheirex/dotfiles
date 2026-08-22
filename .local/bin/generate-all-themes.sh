#!/bin/bash
set -e

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

echo "Refreshing active themes in running applications..."

# Force GTK/Kvantum/icon reload by toggling mode off and back
if command -v gsettings &>/dev/null; then
  scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
  case "$scheme" in
    "'prefer-dark'")
      $HOME/.local/bin/sync-theme-mode.sh light
      sleep 0.3
      $HOME/.local/bin/sync-theme-mode.sh dark
      ;;
    "'prefer-light'")
      $HOME/.local/bin/sync-theme-mode.sh dark
      sleep 0.3
      $HOME/.local/bin/sync-theme-mode.sh light
      ;;
    *)
      $HOME/.local/bin/sync-theme-mode.sh dark
      sleep 0.3
      $HOME/.local/bin/sync-theme-mode.sh auto
      ;;
  esac
fi

notify-send -a "Theme Generator" "Finished theme reloading." "All themes regenerated and refreshed"

echo "All themes regenerated and refreshed successfully."
