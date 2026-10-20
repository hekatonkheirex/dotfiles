#!/bin/bash
set -euo pipefail

source "$HOME/.config/quickshell/scripts/theme-sync-lock.sh"

# Installed outputs cannot be rebuilt without their source checkouts.
for project in material3-expressive-shared material3-expressive-icons material3-expressive-kvantum material3-expressive-theme; do
  if [[ ! -d "$HOME/Projects/$project" ]]; then
    printf 'Missing theme source: %s\nRestore with: %s --skip-sddm\n' \
      "$HOME/Projects/$project" "$HOME/.config/quickshell/scripts/install-ui-suite.sh" >&2
    exit 1
  fi
done

echo "Regenerating all Material 3 Expressive themes from current matugen palette..."

notify-send -a "Theme Generator" "Initializing theme reloading..." "Regenerating from matugen palette"

# Run the 2 simple generators in parallel, then the theme generator separately
# (theme needs sassc/glib which may re-exec in nix-shell)
(
  cd ~/Projects/material3-expressive-icons && python3 generate.py
) &
icons_pid=$!
(
  cd ~/Projects/material3-expressive-kvantum && python3 generate.py
) &
kvantum_pid=$!
generation_failed=0
wait "$icons_pid" || generation_failed=1
wait "$kvantum_pid" || generation_failed=1
if (( generation_failed )); then
  printf 'Icon or Kvantum generation failed; theme regeneration incomplete.\n' >&2
  exit 1
fi

echo "Running theme generator (may take a while)..."
cd ~/Projects/material3-expressive-theme && python3 generate.py

notify-send -a "Theme Generator" "Finished theme regeneration." "All theme outputs regenerated"

echo "All theme outputs regenerated successfully."
