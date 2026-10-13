#!/usr/bin/env bash
# Usage: controls-render.sh [quickshell-root]   (KEEP_PNG=path keeps the render)
# Renders the Elena liquid-tile controls (switch, slider, icon button, pill
# action button, LevelTile) in a scratch HOME, then pixel-checks each against
# the palette color tests/controls/shell.qml reports. Prints PASS|FAIL name and
# "DONE n fail"; exits nonzero on any failure.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/controls/shell.qml" "$home/cfg/shell.qml"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/controls.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/controls.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/controls.png" "$KEEP_PNG"
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::disableSurface' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
python3 -I - "$home/controls.png" "$home/qs.log" <<'PY'
import re, sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
assert im.size == (760, 560), f"size {im.size}"
checks = re.findall(r"CHECK (\S+) (\S+) (\S+) (\d+) (\d+) (\d+)", open(sys.argv[2]).read())
assert len(checks) == 13, f"expected 13 CHECK lines, got {len(checks)}"
fails = 0
for name, x, y, *want in checks:
    got = im.getpixel((int(float(x)), int(float(y))))
    ok = all(abs(got[i] - int(want[i])) <= 8 for i in range(3))  # 0.03 * 255
    fails += not ok
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else f" got {got} want {tuple(map(int, want))}"))
behave = re.findall(r"BEHAVE (\S+) ([01])", open(sys.argv[2]).read())
assert len(behave) == 4, f"expected 4 BEHAVE lines, got {len(behave)}"
for name, ok in behave:
    fails += ok != "1"
    print(("PASS " if ok == "1" else "FAIL ") + name)
print(f"DONE {len(checks) + len(behave)} {fails} fail")
sys.exit(1 if fails else 0)
PY
