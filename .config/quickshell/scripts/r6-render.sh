#!/usr/bin/env bash
# Usage: r6-render.sh [quickshell-root]   (env R6_RENDER_ROOT overrides it;
# KEEP_DIR=path keeps the renders and the log)
# Runs tests/r6/shell.qml in a scratch HOME: MicService against fixture pactl
# output and the mic tab pixels; the toast stack with fake notifications
# (urgency colors, duplicate counts, the limit of five, expiry, clicks).
# Never calls the real pactl source commands or posts real notifications.
set -euo pipefail
root=$(realpath "${R6_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share" "$home/run" "$home/out" "$home/fx"
chmod 700 "$home/run"
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/r6/shell.qml" "$home/cfg/shell.qml"
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts" "$home/.local/share/fonts"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
printf '%s\n' 'Source #1' '	Name: mic_a' '	Description: Built-in Mic' 'Source #2' '	Name: mic_b' '	Description: Headset Mic' > "$home/fx/sources.txt"
: > "$home/r6.log"
HOME="$home" XDG_RUNTIME_DIR="$home/run" RENDER_DIR="$home/out" R6_FIXTURES="$home/fx" R6_LOG="$home/r6.log" \
  QS_NO_RELOAD_POPUP=1 timeout 90 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -z "${KEEP_DIR:-}" ] || { mkdir -p "$KEEP_DIR"; cp "$home"/out/*.png "$home/qs.log" "$KEEP_DIR"/ 2>/dev/null || true; }
[ -s "$home/out/toast.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor'
errs=$(grep -aE "$errpat" "$home/qs.log" | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -aE 'PASS ' "$home/qs.log" | sed 's/.*PASS /ok   /'
qml_ok=1
grep -aq 'DONE r6 0 fail' "$home/qs.log" || { qml_ok=0; grep -aE 'FAIL |DONE' "$home/qs.log" | sed 's/.*\(FAIL \|DONE\)/\1/'; }
grep -ao 'GEOM .*' "$home/qs.log" > "$home/geom.txt"
grep -ao 'COLOR .*' "$home/qs.log" > "$home/colors.txt"
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
X = {n: C[f"x{n}"] for n in (1, 2, 6, 8)}
SURF, CONT = C["surface"], C["surfaceContainer"]
imgs = {}
def im(n):
    if n not in imgs: imgs[n] = Image.open(f"{out}/{n}.png").convert("RGB")
    return imgs[n]
def near(a, b, t=28): return all(abs(a[i] - b[i]) <= t for i in range(3))
def box(img, name):
    x, y, w, h = G[(img, name)]
    return (x, y, x + w, y + h)
def count(img, b, col, t=28):
    p = im(img)
    return sum(near(p.getpixel((x, y)), col, t) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)

# Mic tab: live is x1 filled, muted is x8 blended at 0.4 over the surface.
w = G[("tab-live", "tab")]
check("tab live: x1 fill share (% of box)", round(100 * count("tab-live", box("tab-live", "tab"), X[1], 10) / (w[2] * w[3])), 75)
muted = tuple(round(X[8][i] * 0.4 + SURF[i] * 0.6) for i in range(3))
check("tab muted: x8 at 0.4 share (% of box)", round(100 * count("tab-muted", box("tab-muted", "tab"), X[8], 60) / (w[2] * w[3])), 60)
check("tab muted: not full x1", count("tab-muted", box("tab-muted", "tab"), X[1], 10), 0, 3)
# Toast: card frame x0, glyph per urgency.
for uid, slot in ((1, 6), (2, 2), (3, 1)):
    check(f"toast {uid}: summary glyph x{slot} px", count("toast", box("toast", f"glyph_{uid}"), X[slot]), 40)
    check(f"toast {uid}: body glyph x8 px", count("toast", box("toast", f"body_{uid}"), X[8]), 10)
    check(f"toast {uid}: frame x0 px", count("toast", box("toast", f"card_{uid}"), CONT, 6), 400)
if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("r6 render: ok")
PY
[ "$qml_ok" = 1 ] && [ "$pix_ok" = 1 ] || { echo "FAIL: r6 render"; exit 1; }
