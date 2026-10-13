#!/usr/bin/env bash
# Usage: sidebar-render.sh [quickshell-root]   (env SIDEBAR_RENDER_ROOT overrides it;
# KEEP_PNG=path keeps a copy of the render, even when the check fails)
# Exercises sidebar page navigation and real procfs data in a scratch HOME,
# captures both pages and a short viewport, and checks card/search colors.
set -euo pipefail
root=$(realpath "${SIDEBAR_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/sidebar/shell.qml" "$home/cfg/shell.qml"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/sidebar.png" CLOCK_OUT="$home/clock.png" \
  SEARCH_OUT="$home/search.png" DASHBOARD_OUT="$home/dashboard.png" SHORT_OUT="$home/short.png" \
  QS_NO_RELOAD_POPUP=1 timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/sidebar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
if [ -n "${KEEP_PNG:-}" ]; then
  cp "$home/sidebar.png" "$KEEP_PNG"
  [ ! -s "$home/dashboard.png" ] || cp "$home/dashboard.png" "${KEEP_PNG%.png}-dashboard.png"
  [ ! -s "$home/short.png" ] || cp "$home/short.png" "${KEEP_PNG%.png}-short.png"
fi
# Excluded: mpris absent in scratch session; two WARNs that fire in every scratch
# run (FileView op finished after drop, wayland text-input disableSurface).
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::(disableSurface|enableSurface)' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -q 'DONE sidebar 0 fail' "$home/qs.log" || { cat "$home/qs.log"; exit 1; }
grep -E 'PASS |DONE sidebar' "$home/qs.log"
python3 -I - "$home/sidebar.png" "$home/clock.png" "$home/search.png" "$home/dashboard.png" "$home/short.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (320, 720), f"size {w}x{h}"
card = (0x23, 0x2a, 0x37)       # elenapan surface_container
secondary = (0xf0, 0x62, 0x92)  # today's circle
def near(a, b, t=3): return all(abs(a[i] - b[i]) <= t for i in range(3))
px = list(im.get_flattened_data())
n_card = sum(near(p, card) for p in px)
# Capture the actual clock card instead of pinning its position in the layout.
clock = Image.open(sys.argv[2]).convert("RGB")
n_sec = sum(near(p, secondary) for p in clock.get_flattened_data())
print(f"card px {n_card}, secondary px in clock card {n_sec}")
assert n_card >= 10000, "card surfaces missing"
assert 400 <= n_sec <= 4000, "today's circle missing or wrong color"
# Capture the shared search field, independent of the viewport or page layout.
outline = (0x5b, 0x65, 0x78)    # elenapan outline
primary = (0xc7, 0x7d, 0xc8)
search = Image.open(sys.argv[3]).convert("RGB")
n_border = sum(near(p, outline) or near(p, primary) for p in search.get_flattened_data())
print(f"search field border px {n_border}")
assert n_border >= 300, "search field missing"
assert Image.open(sys.argv[4]).size == (320, 720), "dashboard capture size"
assert Image.open(sys.argv[5]).size == (320, 420), "short viewport capture size"
print("sidebar render: ok")
PY
