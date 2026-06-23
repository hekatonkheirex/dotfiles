#!/bin/bash
# Analyzes current wallpaper brightness and outputs "light" or "dark"

AWWW_CACHE="$HOME/.cache/awww"
WALLPAPER=""

# Try to find current wallpaper from awww cache
if [ -d "$AWWW_CACHE" ]; then
  VERSION_DIR=$(ls -t "$AWWW_CACHE" 2>/dev/null | head -1)
  if [ -n "$VERSION_DIR" ] && [ -f "$AWWW_CACHE/$VERSION_DIR/eDP-1" ]; then
    WALLPAPER=$(strings "$AWWW_CACHE/$VERSION_DIR/eDP-1" | grep -E "\.(jpg|jpeg|png|gif|webp|bmp)" | head -1)
  fi
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
  echo "auto"
  exit 0
fi

# Get mean pixel value via ImageMagick (0-65535)
MEAN=$(magick identify -format "%[mean]" "$WALLPAPER" 2>/dev/null)

if [ -z "$MEAN" ]; then
  echo "auto"
  exit 0
fi

# Threshold: > 30000 (~46% brightness) → light, else dark
if [ "${MEAN%.*}" -gt 30000 ] 2>/dev/null; then
  echo "light"
else
  echo "dark"
fi
