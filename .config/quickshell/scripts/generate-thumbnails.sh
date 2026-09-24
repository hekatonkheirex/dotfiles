#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/quickshell/wallpaper-thumbs"
WALLS_DIR="$HOME/Pictures/Walls"
JOBS=${THUMBNAIL_JOBS:-4}

[[ $JOBS =~ ^[1-9][0-9]*$ ]] || { echo 'THUMBNAIL_JOBS must be a positive integer' >&2; exit 2; }
mkdir -p "$CACHE_DIR"

if [[ ! -d "$WALLS_DIR" ]]; then
    echo "Walls directory not found at $WALLS_DIR"
    exit 0
fi

if command -v magick >/dev/null 2>&1; then
    converter=(magick)
elif command -v convert >/dev/null 2>&1; then
    converter=(convert)
else
    echo 'ImageMagick (magick or convert) is required to generate thumbnails' >&2
    exit 1
fi

pids=()
tmp_files=()
cleanup() { ((${#tmp_files[@]} == 0)) || rm -f -- "${tmp_files[@]}"; }
trap cleanup EXIT
status=0

while IFS= read -r -d '' img; do
    name=${img##*/}
    thumb="$CACHE_DIR/$name"
    [[ -f "$thumb" && ! "$img" -nt "$thumb" ]] && continue
    extension=${name##*.}
    tmp=$(mktemp "$CACHE_DIR/.thumbnail.XXXXXXXX.$extension")
    tmp_files+=("$tmp")
    (
        "${converter[@]}" "$img" -thumbnail '200x130^' -gravity center -extent 200x130 "$tmp" &&
        mv -f -- "$tmp" "$thumb"
    ) &
    pids+=("$!")
    if (( ${#pids[@]} >= JOBS )); then
        wait "${pids[0]}" || status=1
        pids=("${pids[@]:1}")
    fi
done < <(find "$WALLS_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0)

for pid in "${pids[@]}"; do
    wait "$pid" || status=1
done
(( status == 0 )) || { echo 'One or more thumbnails could not be generated' >&2; exit 1; }
echo 'Thumbnail generation complete!'
