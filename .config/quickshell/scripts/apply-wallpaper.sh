#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=theme-sync-lock.sh
source "$script_dir/theme-sync-lock.sh"

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <wallpaper filename>\n' "$0" >&2
  exit 2
fi

wallpaper_name=$1
if [[ -z "$wallpaper_name" || "$wallpaper_name" == */* || "$wallpaper_name" == *\\* ]]; then
  printf 'Invalid wallpaper filename.\n' >&2
  exit 2
fi

wallpaper_dir="$HOME/Pictures/Walls"
wallpaper_path="$wallpaper_dir/$wallpaper_name"
if [[ ! -f "$wallpaper_path" ]]; then
  printf 'Wallpaper not found: %s\n' "$wallpaper_path" >&2
  exit 1
fi

case "${wallpaper_name,,}" in
  *.jpg|*.jpeg|*.png|*.webp) ;;
  *)
    printf 'Unsupported wallpaper type: %s\n' "$wallpaper_name" >&2
    exit 2
    ;;
esac

awww img "$wallpaper_path" \
  --transition-type grow \
  --transition-pos 0,1080 \
  --transition-fps 60 \
  --transition-step 60

# Matugen owns the dynamic Material You palette. Keep wallpaper application
# first so the desktop remains usable even if generation or theme refresh fails.
# Live and Fixed keep separate cache files; a wallpaper change refreshes the
# Live input even while Fixed is selected, then reactivates the chosen source.
matugen_helper="$HOME/.local/bin/matugen-and-cache.sh"
theme_refresh="$HOME/.config/quickshell/scripts/sync-active-palette.sh"
live_cache="$HOME/.cache/matugen/live_palette.json"

matugen_updated=false
color_source="live"
if command -v jq >/dev/null 2>&1; then
  color_source=$(jq -r '.colorSource // "live"' "$HOME/.config/quickshell/settings.json" 2>/dev/null || printf 'live')
fi

if [[ -x "$matugen_helper" ]]; then
  if "$matugen_helper" "$wallpaper_path"; then
    matugen_updated=true
    mkdir -p "${live_cache%/*}"
    cp -- "$HOME/.cache/matugen/current_palette.json" "$live_cache"
  else
    printf 'Matugen palette generation failed; keeping the previous palette.\n' >&2
  fi
else
  printf 'Matugen helper not found: %s\n' "$matugen_helper" >&2
fi

if [[ -x "$theme_refresh" ]]; then
  if [[ "$color_source" == "fixed" ]]; then
    "$theme_refresh" --source fixed --skip-matugen auto ||
      printf 'Fixed palette regeneration or synchronization failed; keeping the active cache.\n' >&2
  elif [[ "$matugen_updated" == true ]]; then
    # matugen-and-cache.sh already rendered the wallpaper cache and its
    # configured templates. Reuse the shared refresh pipeline for the desktop
    # theme generators and active terminal/Niri/editor state.
    "$theme_refresh" --source live --skip-matugen auto ||
      printf 'Theme regeneration or synchronization failed; keeping generated cache.\n' >&2
  fi
else
  printf 'Theme refresh helper not found: %s\n' "$theme_refresh" >&2
fi

# Colors.qml's FileView watchChanges does not reliably live-reload
# ~/.cache/matugen/current_palette.json, so restart Quickshell to pick up
# the fresh palette. ponytail: full QML reload, not just a data refresh —
# revisit if Quickshell adds a real IPC reload/hot-reread for FileView data.
if [[ "$matugen_updated" == true && "$color_source" != "fixed" ]]; then
  systemctl --user restart quickshell.service 2>/dev/null || true
fi
