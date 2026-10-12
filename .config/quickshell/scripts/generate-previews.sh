#!/usr/bin/env bash
# Sharp card-size previews for the wallpaper filmstrip.
#   generate-previews.sh            all missing previews, niced, one run at a time
#   generate-previews.sh <filename> one wallpaper from ~/Pictures/Walls
# Previews are JPEGs, longest side 1600 px, in ~/.cache/quickshell/wallpaper-previews/<filename>.jpg
set -euo pipefail

WALLS_DIR="${WALLS_DIR:-$HOME/Pictures/Walls}"
CACHE_DIR="${PREVIEW_DIR:-$HOME/.cache/quickshell/wallpaper-previews}"
JOBS=${PREVIEW_JOBS:-2}

[[ $JOBS =~ ^[1-9][0-9]*$ ]] || { echo 'PREVIEW_JOBS must be a positive integer' >&2; exit 2; }
mkdir -p "$CACHE_DIR"

if command -v magick >/dev/null 2>&1; then converter=(magick)
elif command -v convert >/dev/null 2>&1; then converter=(convert)
else echo 'ImageMagick (magick or convert) is required' >&2; exit 1
fi

make_preview() {
  local name=$1 src="$WALLS_DIR/$1" out="$CACHE_DIR/$1.jpg" tmp
  [[ -f "$src" ]] || { echo "Wallpaper not found: $src" >&2; return 1; }
  if [[ -f "$out" && ! "$src" -nt "$out" ]]; then return 0; fi
  tmp=$(mktemp "$CACHE_DIR/.preview.XXXXXXXX.jpg")
  if "${converter[@]}" "${src}[0]" -auto-orient -resize '1600x1600>' -strip \
       -sampling-factor 4:2:0 -quality 86 "$tmp"; then
    mv -f -- "$tmp" "$out"
  else
    rm -f -- "$tmp"
    return 1
  fi
}

if [[ $# -gt 1 ]]; then echo "Usage: $0 [wallpaper filename]" >&2; exit 2; fi

if [[ $# -eq 1 ]]; then
  name=$1
  if [[ -z "$name" || "$name" == */* || "$name" == *\\* ]]; then
    echo 'Invalid wallpaper filename.' >&2; exit 2
  fi
  make_preview "$name"
  exit 0
fi

# Bulk: a single run at a time, gentle on the desktop.
exec 9>"$CACHE_DIR/.bulk.lock"
flock -n 9 || exit 0
renice -n 15 -p $$ >/dev/null 2>&1 || true

export -f make_preview
export WALLS_DIR CACHE_DIR
converter_cmd="${converter[*]}"; export converter_cmd
status=0
find "$WALLS_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\0' \
  | xargs -0 -r -P "$JOBS" -n 1 bash -c 'converter=($converter_cmd); make_preview "$1"' _ || status=1
(( status == 0 )) || { echo 'Some previews could not be generated' >&2; exit 1; }
echo 'Preview generation complete!'
