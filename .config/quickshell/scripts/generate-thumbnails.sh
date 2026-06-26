#!/bin/bash
CACHE_DIR="$HOME/.cache/quickshell/wallpaper-thumbs"
WALLS_DIR="$HOME/Pictures/Walls"

mkdir -p "$CACHE_DIR"

if [ ! -d "$WALLS_DIR" ]; then
    echo "Walls directory not found at $WALLS_DIR"
    exit 0
fi

# Loop through all image files in walls directory
find "$WALLS_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r img; do
    name=$(basename "$img")
    thumb="$CACHE_DIR/$name"
    
    # If thumbnail doesn't exist, or is older than the original image, generate it
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        # Resize to 200x130 center cropped
        if command -v magick &>/dev/null; then
            magick "$img" -thumbnail 200x130^ -gravity center -extent 200x130 "$thumb" &
        else
            convert "$img" -thumbnail 200x130^ -gravity center -extent 200x130 "$thumb" &
        fi
        
        # Limit concurrent background jobs to avoid CPU overload
        if [ $(jobs -r -p | wc -l) -ge 4 ]; then
            wait -n
        fi
    fi
done
wait
echo "Thumbnail generation complete!"
