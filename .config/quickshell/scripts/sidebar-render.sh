#!/usr/bin/env bash
# Usage: sidebar-render.sh [quickshell-root]   (env SIDEBAR_RENDER_ROOT overrides it;
# KEEP_PNG=path keeps a copy of the render, even when the check fails)
# Renders SidebarContent under the elenapam palette in a scratch HOME, fails on
# any QML error in the log, and pixel-checks the card surface and today's circle.
set -euo pipefail
root=$(realpath "${SIDEBAR_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
cp "$root/tests/sidebar/shell.qml" "$home/cfg/shell.qml"
printf '{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapam","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/sidebar.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/sidebar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/sidebar.png" "$KEEP_PNG"
# Excluded: mpris absent in scratch session; two WARNs that fire in every scratch
# run (FileView op finished after drop, wayland text-input disableSurface).
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::disableSurface' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
python3 -I - "$home/sidebar.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (320, 720), f"size {w}x{h}"
card = (0x23, 0x2a, 0x37)       # elenapam surface_container
secondary = (0xf0, 0x62, 0x92)  # today's circle
def near(a, b, t=3): return all(abs(a[i] - b[i]) <= t for i in range(3))
px = list(im.getdata())
n_card = sum(near(p, card) for p in px)
# Clock card is the top card: y from spacingMedium (12) to ~162, battery pill
# starts ~175 (measured on the render). The mic bar fill and separator dots are
# also secondary, so the circle is only proven by counting inside this band.
CLOCK_Y1 = 170
n_sec = sum(near(p, secondary) for p in px[: w * CLOCK_Y1])
print(f"card px {n_card}, secondary px in clock card (y<{CLOCK_Y1}) {n_sec}")
assert n_card >= 10000, "card surfaces missing"
assert 400 <= n_sec <= 4000, "today's circle missing or wrong color"
# Search field: a bordered row under the level bars. Its border is Colors.outline
# (unfocused) or Colors.primary (focused); the level bars card ends above FIELD_Y0.
outline = (0x5b, 0x65, 0x78)    # elenapam outline
primary = (0xc7, 0x7d, 0xc8)
FIELD_Y0 = 655
n_border = sum(near(p, outline) or near(p, primary) for p in px[w * FIELD_Y0:])
print(f"search field border px (y>={FIELD_Y0}) {n_border}")
assert n_border >= 300, "search field missing"
print("sidebar render: ok")
PY
