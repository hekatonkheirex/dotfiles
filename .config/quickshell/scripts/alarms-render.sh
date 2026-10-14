#!/usr/bin/env bash
# Usage: alarms-render.sh [quickshell-root]   (env ALARMS_RENDER_ROOT overrides it;
# KEEP_DIR=path keeps a copy of the renders, even when the check fails)
# Renders AlarmsContent under the elenapan palette in a scratch HOME
# (tests/alarms/shell.qml): browse (a), quick entry (q), standard entry with
# the label field active (s) and the empty state (e). Runs click/key checks and
# AlarmService integration against a fake clock and fake sound/notify commands
# (never the real ones), then pixel-checks accents. Boxes come from GEOM lines.
set -euo pipefail
root=$(realpath "${ALARMS_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share" "$home/run" "$home/out"
chmod 700 "$home/run"
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/alarms/shell.qml" "$home/cfg/shell.qml"
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts" "$home/.local/share/fonts"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
: > "$home/alarm.log"
HOME="$home" XDG_RUNTIME_DIR="$home/run" RENDER_DIR="$home/out" ALARM_LOG="$home/alarm.log" \
  QML_XHR_ALLOW_FILE_READ=1 QS_NO_RELOAD_POPUP=1 \
  timeout 90 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -z "${KEEP_DIR:-}" ] || { mkdir -p "$KEEP_DIR"; cp "$home"/out/*.png "$home/qs.log" "$KEEP_DIR"/ 2>/dev/null || true; }
[ -s "$home/out/a.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'got operation finished from dropped operation|QWaylandTextInputv3::(disableSurface|enableSurface)' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -E 'PASS ' "$home/qs.log" | sed 's/.*PASS /ok   /'
qml_ok=1
grep -q 'DONE alarms 0 fail' "$home/qs.log" || { qml_ok=0; grep -E 'FAIL |DONE' "$home/qs.log" | sed 's/.*\(FAIL \|DONE\)/\1/' || tail -20 "$home/qs.log"; }
grep -o 'GEOM .*' "$home/qs.log" > "$home/geom.txt"
grep -o 'COLOR .*' "$home/qs.log" > "$home/colors.txt"
pix_ok=1
python3 -I - "$home/out" "$home/geom.txt" "$home/colors.txt" <<'PY' || pix_ok=0
import sys
from PIL import Image
out = sys.argv[1]
G = {}
for line in open(sys.argv[2]):
    _, img, name, x, y, w, h = line.split()
    G[(img, name)] = tuple(int(v) for v in (x, y, w, h))
def hx(s): return tuple(int(s[i:i+2], 16) for i in (1, 3, 5))
C = {}
for line in open(sys.argv[3]):
    _, name, col = line.split()
    C[name] = hx(col)
X = {n: C[f"x{n}"] for n in (1, 2, 3, 6, 8)}
SURF, CONT, FG = C["surface"], C["surfaceContainer"], C["fg"]
imgs = {}
def im(name):
    if name not in imgs: imgs[name] = Image.open(f"{out}/{name}.png").convert("RGB")
    return imgs[name]
def near(a, b, t=24): return all(abs(a[i] - b[i]) <= t for i in range(3))
def box(img, name):
    x, y, w, h = G[(img, name)]
    return (x, y, x + w, y + h)
def count(img, b, col, t=24):
    p = im(img)
    return sum(near(p.getpixel((x, y)), col, t) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)

# Browse: glyphs x3 on both dual buttons, delete x1, prev disabled x8, next x6.
check("a: quick glyph x3 px", count("a", box("a", "btn_quick"), X[3]), 20)
check("a: standard glyph x3 px", count("a", box("a", "btn_standard"), X[3]), 20)
check("a: delete glyph x1 px", count("a", box("a", "btn_delete"), X[1], 45), 6)  # thin 2 px stroke, blended
check("a: prev disabled x8 px", count("a", box("a", "btn_prev"), X[8]), 6)
check("a: prev not x6 px", count("a", box("a", "btn_prev"), X[6], 4), 0, 3)
check("a: next x6 px", count("a", box("a", "btn_next"), X[6]), 6)
check("a: time digits fg px", count("a", box("a", "hour"), FG), 60)
check("a: separator x3 px", count("a", box("a", "separator"), X[3]), 15)
check("a: top label x8 px", count("a", box("a", "topLabel"), X[8]), 40)
# Empty: everything dimmed to x8, nothing fg.
check("e: delete disabled x8 px", count("e", box("e", "btn_delete"), X[8]), 15)
check("e: no x1 on delete", count("e", box("e", "btn_delete"), X[1], 4), 0, 3)
check("e: dashes x8 px", count("e", box("e", "hour"), X[8]), 40)
check("e: all clear x8 px", count("e", box("e", "bottomLabel"), X[8]), 60)
# Quick: standard dimmed x8, cancel x1 and confirm x2 fills, label typed in x3.
check("q: standard dimmed x8 px", count("q", box("q", "btn_standard"), X[8]), 20)
check("q: quick still x3 px", count("q", box("q", "btn_quick"), X[3]), 20)
check("q: cancel fill x1 px", count("q", box("q", "btn_cancel"), X[1], 6), 200)
check("q: confirm fill x2 px", count("q", box("q", "btn_confirm"), X[2], 6), 200)
check("q: step glyphs x6 px", count("q", box("q", "step_plus_5"), X[6]), 15)
check("q: active label x3 px", count("q", box("q", "bottomLabel"), X[3]), 30)
# Standard: label field active (hours/minutes back to fg), quick dimmed.
check("s: quick dimmed? no, standard active x3 px", count("s", box("s", "btn_standard"), X[3]), 20)
check("s: quick dimmed x8 px", count("s", box("s", "btn_quick"), X[3]), 0, 3)
check("s: step -h/+h glyph x6 px", count("s", box("s", "step_plus_60"), X[6]), 15)

if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("alarms render: ok")
PY
[ "$qml_ok" = 1 ] && [ "$pix_ok" = 1 ] || { echo "FAIL: alarms render"; exit 1; }
