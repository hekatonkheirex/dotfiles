#!/usr/bin/env bash
# Usage: bottom-bar-render.sh [quickshell-root]   (env BOTTOM_BAR_RENDER_ROOT
# overrides it; KEEP_PNG=path keeps a copy of the render, even when the check fails)
# Renders two BottomBarContent instances under the elenapan palette in a scratch
# HOME, fails on any QML error in the log, and pixel-checks cluster surfaces,
# hover border, dock indicators, battery (40 % so the half part shows), signal, volume ring, alarm pill, and
# that the icon glyphs are not tofu.
set -euo pipefail
root=$(realpath "${BOTTOM_BAR_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share/fonts" "$home/run"
chmod 700 "$home/run"
# qs runtime files stay out of /run/user; the compositor socket is linked in.
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/bottom-bar/shell.qml" "$home/cfg/shell.qml"
# The fontconfig rule renaming remix.ttf to "ElenaIcons" lives in the real
# config dir; without it the bar glyphs render as tofu.
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts/icomoon" "$home/.local/share/fonts/icomoon"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" XDG_RUNTIME_DIR="$home/run" GOLDEN_OUT="$home/bar.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/bar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/bar.png" "$KEEP_PNG"
# Excluded: mpris absent in scratch session; two WARNs that fire in every scratch
# run (FileView op finished after drop, wayland text-input disableSurface).
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::disableSurface' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
python3 -I - "$home/bar.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
assert im.size == (1100, 170), f"size {im.size}"
def hx(s): return tuple(int(s[i:i+2], 16) for i in (1, 3, 5))
SURF, HIGH, ERR = hx("#1a1f2b"), hx("#343c4d"), hx("#ff6b6b")
SEC, TER, PRI = hx("#f06292"), hx("#5bb8d4"), hx("#c77dc8")
INVP, FGTC, OUT = hx("#8e4f90"), hx("#cfeefa"), hx("#5b6578")
FGS, BG = hx("#f2f4f8"), hx("#101216")
def near(a, b, t=8): return all(abs(a[i] - b[i]) <= t for i in range(3))
def count(box, col, t=8):
    x0, y0, x1, y1 = box
    return sum(near(im.getpixel((x, y)), col, t) for x in range(x0, x1) for y in range(y0, y1))
def area(box): return (box[2] - box[0]) * (box[3] - box[1])
def dp(n): return int(n * 1.5 + 0.5)
W, BH = 1100, dp(43)               # stage width, bar height (65)
OFF = {"A": 0, "B": 85}            # bar A: idle; bar B: hover on glance
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)
def patch(cx, cy, r=1): return (cx - r, cy - r, cx + r + 1, cy + r + 1)

# 2. cluster surface and rounded outer corners
for lab, (x, y) in (("left", (20, 30)), ("right", (W - 20, 30))):
    box = (x, y, x + 6, y + 6)
    check(f"A {lab} cluster surface px", count(box, SURF, 3), 36, 36)
check("A left cluster corner is stage bg", int(near(im.getpixel((449, 0)), BG, 3)), 1, 1)
check("A right cluster corner is stage bg", int(near(im.getpixel((W - 450, 0)), BG, 3)), 1, 1)

# 3. hover border: bottom dp(3) strip under the glance button, accent only in B
for lab in "AB":
    y = OFF[lab] + BH - dp(3)
    n = count((10, y, 140, y + dp(3)), ERR)
    if lab == "B": check("B glance border px", n, int(0.95 * 130 * dp(3)))
    else: check("A glance border px", n, 0, 0)
y = OFF["B"] + BH - dp(3)
check("B other-button border px", count((160, y, 290, y + dp(3)), ERR), 0, 0)

# 4. dock: items are dp(35) wide, dp(4) apart, centred; the focused indicator
# is dp(6) x dp(3) at the item's bottom, dp(6) above the bar bottom.
iw, gap = dp(35), dp(4)
dx0 = (W - (3 * iw + 2 * gap)) / 2
ix = [int(dx0 + i * (iw + gap)) for i in range(3)]
ybot = BH - dp(6)                  # item bottom
band = lambda i: (ix[i] + iw // 2 - 5, ybot - dp(3) - 1, ix[i] + iw // 2 + 5, ybot)
item = lambda i: (ix[i], 0, ix[i] + iw, ybot)
b0 = (ix[0] + iw // 2 - 3, ybot - dp(3) + 1, ix[0] + iw // 2 + 4, ybot - 1)
check("A kitty indicator px (inversePrimary)", count(b0, INVP), int(0.9 * area(b0)))
accents = (ERR, SEC, TER, PRI, INVP, FGTC)
check("A firefox indicator-band accent px", sum(count(band(1), a) for a in accents), 0, 0)
check("A firefox glyph muted px (outline)", count(item(1), OUT), 150)
check("A firefox glyph accent px (tertiary)", count(item(1), TER), 0, 0)
check("A mpv glyph px (fgTertiaryContainer)", count(item(2), FGTC), 100)
check("A mpv indicator-band px", count(band(2), FGTC), 0, 0)

# 5. battery stack: right cluster, third button; 3 parts of (dp(23)-8)/3 = 9
bx = W - 57                        # stack centre x (measured: 1033..1054)
stack = lambda lab, k: patch(bx, OFF[lab] + 19 + 13 * k, 3)   # part centres 19, 32, 45
half = tuple((a + b) // 2 for a, b in zip(FGTC, SURF))
for k in range(3):
    check(f"A battery part {k} full px", count(stack("A", k), FGTC), area(stack("A", k)))
check("B battery top empty px", count(stack("B", 0), HIGH), area(stack("B", 0)))
check("B battery middle half px", count(stack("B", 1), half), area(stack("B", 1)))
check("B battery bottom full px", count(stack("B", 2), FGTC), area(stack("B", 2)))

# 6. signal bars: x centres 726, 738, 750, 762; heights grow left to right
sx = [W - 374 + 12 * i for i in range(4)]
def colh(lab, x, col):
    return sum(near(im.getpixel((x, y)), col) for y in range(OFF[lab], OFF[lab] + BH))
for i, x in enumerate(sx):
    mid = patch(x, OFF["A"] + BH // 2, 2)
    check(f"A signal bar {i} px (primary)", count(mid, PRI), area(mid))
    midb = patch(x, OFF["B"] + BH // 2, 2)
    want, nm = (PRI, "primary") if i < 2 else (HIGH, "container")
    check(f"B signal bar {i} px ({nm})", count(midb, want), area(midb))
hs = [colh("A", x, PRI) for x in sx]
print("signal bar heights", hs)
check("A signal heights strictly increase", int(all(a < b for a, b in zip(hs, hs[1:]))), 1, 1)

# 7. volume ring: centre (394, 32), outer radius dp(23)/2 = 17.5, stroke dp(5)
import math
rcx, rr = 394, 13
def ring(lab, deg):    # deg counter-clockwise from 12 o'clock
    t = math.radians(deg)
    return patch(int(round(rcx - rr * math.sin(t))), int(round(OFF[lab] + 32 - rr * math.cos(t))), 1)
for deg in range(0, 360, 45):
    b = ring("A", deg)
    check(f"A ring {deg:3d} deg px (fgSurface)", count(b, FGS), area(b))
for deg in (20, 72, 124):
    b = ring("B", deg)
    check(f"B ring {deg:3d} deg px (muted arc)", count(b, OUT), area(b))
for deg in (180, 230, 290, 340):
    b = ring("B", deg)
    check(f"B ring {deg:3d} deg px (backdrop)", count(b, HIGH), area(b))

# 8. alarm count: pill in A, slashed line in B (button 2 of the right cluster)
ab = lambda lab: (W - 232, OFF[lab] + 10, W - 180, OFF[lab] + BH - 10)
check("A alarm pill px (container)", count(ab("A"), HIGH), 700)
check("A alarm slash px (tertiary)", count(ab("A"), TER), 0, 0)
check("B alarm slash px (tertiary)", count(ab("B"), TER), 150)
check("B alarm pill px (container)", count(ab("B"), HIGH), 0, 20)

# 9. glyphs are not tofu or the wrong file: each button glyph of bar A (command,
# star, headphones, shield, bell, bolt) measures 38..60 accent px at 12pt.
glyphs = (("clock command", (20, ERR), 60), ("date star", (170, SEC), 45),
          ("media headphones", (320, INVP), 38), ("network shield", (W - 430, PRI), 30),
          ("alarms bell", (W - 280, TER), 54), ("battery bolt", (W - 130, FGTC), 38))
for nm, (x, col), want in glyphs:
    check(f"A {nm} glyph accent px", count((x, 15, x + 45, 50), col), int(want * 0.6), int(want * 1.6))

if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("bottom bar render: ok")
PY
