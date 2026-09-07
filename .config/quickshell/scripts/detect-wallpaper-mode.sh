#!/usr/bin/env bash
set -euo pipefail

cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
state_file="$cache_home/quickshell/current-wallpaper"
wallpaper="${1:-}"

if [[ -z "$wallpaper" && -r "$state_file" ]]; then
    wallpaper=$(head -n 1 -- "$state_file")
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    awww_cache="$cache_home/awww"
    latest_cache=$(find "$awww_cache" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true)
    if [[ -n "$latest_cache" && -r "$latest_cache" ]]; then
        wallpaper=$(strings -- "$latest_cache" | awk '
            tolower($0) ~ /\.(jpe?g|png|webp|gif|bmp|tiff?|avif)$/ { path = $0 }
            END { print path }
        ')
    fi
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]] || ! command -v magick >/dev/null 2>&1; then
    printf 'dark\n'
    exit 0
fi

mean=$(magick identify -format '%[fx:mean]' -- "$wallpaper" 2>/dev/null || true)
if [[ -z "$mean" ]]; then
    printf 'dark\n'
elif awk -v value="$mean" 'BEGIN { exit !(value >= 0.46) }'; then
    printf 'light\n'
else
    printf 'dark\n'
fi
