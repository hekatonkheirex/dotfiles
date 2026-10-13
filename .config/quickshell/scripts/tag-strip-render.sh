#!/usr/bin/env bash
# Usage: tag-strip-render.sh [quickshell-root]
# Renders TagStripBlocks with a fixed model under the elenapan palette and
# checks the block colors. Exits non-zero on mismatch.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/tag-strip/shell.qml" "$home/cfg/shell.qml"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/strip.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/strip.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
python3 -I - "$home/strip.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (450, 8), f"size {w}x{h}"
surface = (0x1a, 0x1f, 0x2b)
accents = [(0xc7, 0x7d, 0xc8), (0xf0, 0x62, 0x92), (0x5b, 0xb8, 0xd4)]
def blend(a, alpha):
    return tuple(round(alpha * a[i] + (1 - alpha) * surface[i]) for i in range(3))
# model: idx1 occupied, idx2 focused, idx3 empty, idx4 occupied, idx5 empty, idx6 focused
want = [blend(accents[0], .35), accents[1], blend(accents[2], .08),
        blend(accents[0], .35), blend(accents[1], .08), accents[2]]
bad = 0
for i, exp in enumerate(want):
    got = im.getpixel((i * 75 + 37, 4))
    ok = all(abs(got[c] - exp[c]) <= 3 for c in range(3))
    bad += not ok
    print(("ok   " if ok else "FAIL ") + f"block {i + 1}: got {got} want {exp}")
sys.exit(1 if bad else 0)
PY
