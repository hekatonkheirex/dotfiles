#!/usr/bin/env bash
set -euo pipefail

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
matugen_helper="$HOME/.local/bin/matugen-and-cache.sh"
theme_generator="$HOME/.local/bin/generate-all-themes.sh"
theme_sync="$HOME/.local/bin/sync-theme-mode.sh"

matugen_updated=false
if [[ -x "$matugen_helper" ]]; then
  if "$matugen_helper" "$wallpaper_path"; then
    matugen_updated=true
  else
    printf 'Matugen palette generation failed; keeping the previous palette.\n' >&2
  fi
else
  printf 'Matugen helper not found: %s\n' "$matugen_helper" >&2
fi

if [[ "$matugen_updated" == true && -x "$theme_generator" ]]; then
  "$theme_generator" || printf 'Theme regeneration failed; keeping generated cache.\n' >&2
fi

if [[ "$matugen_updated" == true && -x "$theme_sync" ]]; then
  "$theme_sync" auto || printf 'Theme mode synchronization failed.\n' >&2
fi

# Colors.qml's FileView watchChanges does not reliably live-reload
# ~/.cache/matugen/current_palette.json, so restart Quickshell to pick up
# the fresh palette. ponytail: full QML reload, not just a data refresh —
# revisit if Quickshell adds a real IPC reload/hot-reread for FileView data.
if [[ "$matugen_updated" == true ]]; then
  systemctl --user restart quickshell.service 2>/dev/null || true
fi
