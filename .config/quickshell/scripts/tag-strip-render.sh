#!/usr/bin/env bash
# Usage: tag-strip-render.sh [quickshell-root]
# Renders three TagStripBlocks rows (tests/tag-strip/shell.qml) under the
# elenapan palette and checks her colors, opacities, hover and rounded
# bottom corners. Exits non-zero on mismatch.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/tag-strip/shell.qml" "$home/cfg/shell.qml"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/strip.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/strip.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
sleep 0.5
grep -ao 'COLOR .*' "$home/qs.log" > "$home/colors.txt"
python3 -I - "$home/strip.png" "$home/colors.txt" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
assert im.size == (450, 24), f"size {im.size}"
C = {}
for line in open(sys.argv[2]):
    _, name, col = line.split()
    C[name] = tuple(int(col[i:i+2], 16) for i in (1, 3, 5))
surf = C["surface"]
def mix(a, alpha): return tuple(round(alpha * a[i] + (1 - alpha) * surf[i]) for i in range(3))
X = {n: C[f"x{n}"] for n in range(1, 7)}
# Her order: ws1 x1, ws2 x3, ws3 x2, ws4 x6, ws5 x4, ws6 x5. Width 75 each.
slots = {1: X[1], 2: X[3], 3: X[2], 4: X[6], 5: X[4], 6: X[5]}
def px(x, y): return im.getpixel((x, y))
def near(a, b, t=3): return all(abs(a[i] - b[i]) <= t for i in range(3))
bad = 0
def check(name, got, want):
    global bad
    ok = near(got, want)
    bad += not ok
    print(("ok   " if ok else "FAIL ") + f"{name}: got {got} want {want}")
cx = lambda i: (i - 1) * 75 + 37
# Row A (y 0..7): focused solid, occupied 0.3, empty invisible.
check("A ws1 occupied .3 x1", px(cx(1), 2), mix(slots[1], .3))
check("A ws2 focused x3", px(cx(2), 2), slots[2])
check("A ws3 empty invisible", px(cx(3), 2), surf)
check("A ws4 occupied .3 x6", px(cx(4), 2), mix(slots[4], .3))
check("A ws5 empty invisible", px(cx(5), 2), surf)
check("A ws6 focused x5", px(cx(6), 2), slots[6])
# Rounded corners (bottom, radius = strip height): ws2 right (next is empty).
check("A ws2 bottom-right corner rounded away", px(2 * 75 - 1, 7), surf)
check("A ws2 top-right corner kept", px(2 * 75 - 1, 0), slots[2])
check("A ws2 bottom-left stays square (left is occupied)", px(75, 7), slots[2])
check("A ws4 bottom-left rounded (left is empty)", px(3 * 75 + 0, 7), surf)
check("A ws4 bottom-right rounded (right is empty)", px(4 * 75 - 1, 7), surf)
check("A ws1 bottom-left square (row end)", px(0, 7), mix(slots[1], .3))
check("A ws6 bottom-right square (row end)", px(6 * 75 - 1, 7), slots[6])
# Row B (y 8..15): empty ws3 hovered is .2, others unchanged.
check("B ws3 empty hover .2 x2", px(cx(3), 10), mix(slots[3], .2))
check("B ws1 occupied unchanged", px(cx(1), 10), mix(slots[1], .3))
# Row C (y 16..23): occupied ws1 hovered is .6.
check("C ws1 occupied hover .6 x1", px(cx(1), 18), mix(slots[1], .6))
check("C ws3 empty still invisible", px(cx(3), 18), surf)
sys.exit(1 if bad else 0)
PY
echo "tag-strip render: ok"
