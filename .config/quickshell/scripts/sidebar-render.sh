#!/usr/bin/env bash
# Usage: sidebar-render.sh [quickshell-root]
# Renders SidebarContent under the elenapam palette in a scratch HOME, fails on
# any QML error in the log, and pixel-checks the card surface and today's circle.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
cp "$root/tests/sidebar/shell.qml" "$home/cfg/shell.qml"
printf '{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapam","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/sidebar.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/sidebar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
if grep -E "(TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR)" "$home/qs.log" \
   | grep -v "Cannot find the mpris\|dbus" | head -5 | grep -q .; then
  echo "FAIL: QML errors"; grep -E "(TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR)" "$home/qs.log" | head -8; exit 1
fi
[ -z "${KEEP_PNG:-}" ] || cp "$home/sidebar.png" "$KEEP_PNG"
python3 -I - "$home/sidebar.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (320, 640), f"size {w}x{h}"
card = (0x23, 0x2a, 0x37)       # elenapam surface_container
secondary = (0xf0, 0x62, 0x92)  # today's circle
def near(a, b, t=3): return all(abs(a[i] - b[i]) <= t for i in range(3))
px = list(im.getdata())
n_card = sum(near(p, card) for p in px)
n_sec = sum(near(p, secondary) for p in px)
print(f"card px {n_card}, secondary px {n_sec}")
assert n_card >= 10000, "card surfaces missing"
assert 300 <= n_sec <= 4000, "today's circle missing or wrong color"
print("sidebar render: ok")
PY
