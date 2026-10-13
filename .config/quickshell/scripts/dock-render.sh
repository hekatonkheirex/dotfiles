#!/usr/bin/env bash
# Usage: dock-render.sh [quickshell-root]   (env DOCK_RENDER_ROOT overrides it;
# KEEP_PNG=path keeps a copy of the render, even when the check fails)
# Renders DockContent under the elenapan palette in a scratch HOME, fails on
# any QML error in the log, and pixel-checks tiles and the three indicator states.
set -euo pipefail
root=$(realpath "${DOCK_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
cp "$root/tests/dock/shell.qml" "$home/cfg/shell.qml"
printf '{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/dock.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/dock.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/dock.png" "$KEEP_PNG"
# Excluded: mpris absent in scratch session; two WARNs that fire in every scratch
# run (FileView op finished after drop, wayland text-input disableSurface).
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::disableSurface' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
python3 -I - "$home/dock.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (214, 81), f"size {w}x{h}"
tile_c = (0x23, 0x2a, 0x37)     # elenapan surface_container
accents = [(0xc7, 0x7d, 0xc8), (0xf0, 0x62, 0x92), (0x5b, 0xb8, 0xd4)]
def near(a, b, t=3): return all(abs(a[i] - b[i]) <= t for i in range(3))
def count(box, col):
    x0, y0, x1, y1 = box
    return sum(near(im.getpixel((x, y)), col) for x in range(x0, x1) for y in range(y0, y1))
# Geometry: item width 50 + 2*8 = 66, tile 50 at x offset 8; content row is
# centered in the 214x81 stage (8 px margin each side). Indicator row sits
# 8 px under the tile and is 7 px high.
X0, Y0 = 8, 8
tiles = [(X0 + 66 * i + 8, Y0) for i in range(3)]
band_y = (Y0 + 50 + 8, Y0 + 50 + 8 + 7)
bands = [(tx, band_y[0], tx + 50, band_y[1]) for tx, _ in tiles]
# (a) tile surface: left edge strip of each tile, clear of the corner radius
# and of the 32 px icon box (icon starts 9 px in).
for i, (tx, ty) in enumerate(tiles):
    n = count((tx + 1, ty + 18, tx + 8, ty + 32), tile_c)
    print(f"tile {i} surface px {n}")
    assert n >= 60, f"tile {i} surface missing"
# (b) pinned-but-closed: nothing in the indicator band
n0 = sum(count(bands[0], a) for a in accents)
print(f"item 0 band accent px {n0}")
assert n0 == 0, "indicator under pinned-but-closed item"
# (c) running, unfocused: a 7 px dot in the item's accent (secondary)
n1 = count(bands[1], accents[1])
print(f"item 1 band secondary px {n1}")
assert 20 <= n1 <= 80, "dot missing or wrong size"
# (d) focused: 34x7 bar in tertiary
n2 = count(bands[2], accents[2])
print(f"item 2 band tertiary px {n2}")
assert n2 >= 150, "focused bar missing"
print("dock render: ok")
PY
