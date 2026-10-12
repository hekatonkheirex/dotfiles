#!/usr/bin/env bash
# Apply a random wallpaper from ~/Pictures/Walls, avoiding the current one when
# there is a choice. WALLS_DIR, CURRENT_WALLPAPER and APPLY_CMD exist for tests.
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WALLS_DIR="${WALLS_DIR:-$HOME/Pictures/Walls}"
APPLY_CMD="${APPLY_CMD:-$script_dir/apply-wallpaper.sh}"

current="${CURRENT_WALLPAPER-}"
if [[ -z "${CURRENT_WALLPAPER+x}" ]] && command -v awww >/dev/null 2>&1; then
  current=$(awww query 2>/dev/null | sed -n 's#.*image: .*/##p' | head -1 || true)
fi

mapfile -d '' -t images < <(
  find "$WALLS_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\0'
)
((${#images[@]} > 0)) || { echo "No wallpapers in $WALLS_DIR" >&2; exit 1; }

candidates=()
for name in "${images[@]}"; do
  [[ "$name" == "$current" && ${#images[@]} -gt 1 ]] || candidates+=("$name")
done

pick=${candidates[RANDOM % ${#candidates[@]}]}
exec "$APPLY_CMD" "$pick"
