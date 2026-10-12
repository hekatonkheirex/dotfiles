#!/usr/bin/env bash
# Gate test: bash tests/wallpaper-filmstrip/previews.test.sh
set -euo pipefail
here=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
script="$here/../../scripts/generate-previews.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export WALLS_DIR="$tmp/walls" PREVIEW_DIR="$tmp/previews"
mkdir -p "$WALLS_DIR"
magick -size 3200x1800 gradient:red-blue "$WALLS_DIR/big one.png"
magick -size 800x600 xc:green "$WALLS_DIR/small.jpg"
printf 'not an image' > "$WALLS_DIR/broken.png"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Single mode: longest side capped at 1600, aspect kept, name with a space.
bash "$script" "big one.png"
dims=$(identify -format '%wx%h' "$PREVIEW_DIR/big one.png.jpg")
[[ $dims == 1600x900 ]] || fail "expected 1600x900, got $dims"

# Small images are not enlarged.
bash "$script" "small.jpg"
dims=$(identify -format '%wx%h' "$PREVIEW_DIR/small.jpg.jpg")
[[ $dims == 800x600 ]] || fail "expected 800x600, got $dims"

# Up to date previews are left alone.
before=$(stat -c %Y.%y "$PREVIEW_DIR/big one.png.jpg")
sleep 1.1
bash "$script" "big one.png"
[[ $before == "$(stat -c %Y.%y "$PREVIEW_DIR/big one.png.jpg")" ]] || fail "preview regenerated though up to date"

# A newer source regenerates it.
touch "$WALLS_DIR/big one.png"
sleep 1.1; touch "$WALLS_DIR/big one.png"
bash "$script" "big one.png"
[[ $before != "$(stat -c %Y.%y "$PREVIEW_DIR/big one.png.jpg")" ]] || fail "newer source did not regenerate"

# Validation: traversal, empty, missing file, unreadable image, too many args.
for bad in "../x.png" "a/b.png" ""; do
  if bash "$script" "$bad" 2>/dev/null; then fail "accepted invalid name '$bad'"; fi
done
if bash "$script" "nope.png" 2>/dev/null; then fail "accepted missing file"; fi
if bash "$script" "broken.png" 2>/dev/null; then fail "accepted a broken image"; fi
[[ ! -e "$PREVIEW_DIR/broken.png.jpg" ]] || fail "left a partial preview for a broken image"
if bash "$script" a b 2>/dev/null; then fail "accepted two arguments"; fi

# Bulk: fills in the rest, reports failure for the broken one, leaves no temp files.
rm -f "$PREVIEW_DIR"/*.jpg
if bash "$script" 2>/dev/null; then fail "bulk run should report the broken image"; fi
[[ -f "$PREVIEW_DIR/big one.png.jpg" && -f "$PREVIEW_DIR/small.jpg.jpg" ]] || fail "bulk missed valid images"
if compgen -G "$PREVIEW_DIR/.preview.*" >/dev/null; then fail "temp files left behind"; fi
echo "PASS previews"
