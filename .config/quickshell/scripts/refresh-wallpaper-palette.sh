#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
palette_dir="$cache_home/quickshell/palettes"
live_palette="$palette_dir/live.json"
state_file="$cache_home/quickshell/current-wallpaper"
legacy_palette_dir="$cache_home/matugen"
legacy_palette="$legacy_palette_dir/current_palette.json"
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

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    printf 'No current wallpaper was found.\n' >&2
    exit 1
fi

if [[ ! -x /usr/bin/matugen ]]; then
    printf 'Matugen executable not found at /usr/bin/matugen.\n' >&2
    exit 1
fi

command -v jq >/dev/null 2>&1 || {
    printf 'jq is required to normalize the Matugen palette.\n' >&2
    exit 1
}

umask 077
mkdir -p -- "$palette_dir" "$(dirname -- "$state_file")" "$legacy_palette_dir"
raw_file=$(mktemp "$palette_dir/matugen.XXXXXX.json")
palette_file=$(mktemp "$palette_dir/live.XXXXXX.json")
state_tmp=$(mktemp "$(dirname -- "$state_file")/current-wallpaper.XXXXXX")
legacy_tmp=$(mktemp "$legacy_palette_dir/current_palette.XXXXXX")
cleanup() {
    rm -f -- "$raw_file" "$palette_file" "$state_tmp" "$legacy_tmp"
}
trap cleanup EXIT

/usr/bin/matugen --json hex --type scheme-fidelity --prefer saturation image "$wallpaper" >"$raw_file"

jq -e --arg wallpaper "$wallpaper" '
    def palette($mode):
        .colors | with_entries(.value = .value[$mode].color);
    {
        source: "wallpaper",
        wallpaper: $wallpaper,
        generatedAt: (now | todateiso8601),
        light: palette("light"),
        dark: palette("dark")
    }
' "$raw_file" >"$palette_file"

jq -e --arg wallpaper "$wallpaper" '{
    "scheme-expressive": {
        light: .light,
        dark: .dark
    },
    _seed: $wallpaper
}' "$palette_file" >"$legacy_tmp"

mv -f -- "$palette_file" "$live_palette"
mv -f -- "$legacy_tmp" "$legacy_palette"
printf '%s\n' "$wallpaper" >"$state_tmp"
mv -f -- "$state_tmp" "$state_file"
trap - EXIT

sync_script="$script_dir/sync-material3-expressive.sh"
if [[ -x "$sync_script" ]] && ! "$sync_script"; then
    printf 'Material 3 Expressive synchronization failed; Quickshell palette remains available.\n' >&2
fi
