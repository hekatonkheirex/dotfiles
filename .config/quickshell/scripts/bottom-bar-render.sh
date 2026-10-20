#!/usr/bin/env bash
# Usage: bottom-bar-render.sh [quickshell-root]   (env BOTTOM_BAR_RENDER_ROOT
# overrides it; KEEP_PNG=path keeps a copy of the render, even when the check fails)
# Renders three BottomBarContent instances under the elenapan palette in a scratch
# HOME, fails on QML errors, and pixel-checks cluster surfaces, hover borders,
# dock indicators, battery parts, signal, volume ring and tray pill.
# Icon-font identity is checked separately by bar-font-check.sh.
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
# The fontconfig rules naming the icon files ElenaIcons1..3 live in the real
# config dir; without it the bar glyphs render as tofu.
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts/icomoon" "$home/.local/share/fonts/icomoon"
# Her text font for the clock and date pills, when installed.
kyok="$real_home/.local/share/fonts/Kyok"
[ -d "$kyok" ] && ln -s "$kyok" "$home/.local/share/fonts/Kyok"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
# Empty XDG_DATA_DIRS: no desktop entries resolve, so the dock items render their
# glyph fallback on any machine (the icon path is covered by the live shell).
HOME="$home" XDG_RUNTIME_DIR="$home/run" XDG_DATA_DIRS="$home/none" GOLDEN_OUT="$home/bar.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/bar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/bar.png" "$KEEP_PNG"
# Excluded: mpris absent in scratch session; two WARNs that fire in every scratch
# run (FileView op finished after drop, wayland text-input disableSurface).
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::disableSurface' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
# The pills use Kyok medium when it is installed, else the shell font.
fam=$(grep -o 'textFamily=.*' "$home/qs.log" | head -1)
want="textFamily=Kyok medium"; [ -d "$kyok" ] || want="textFamily=Roboto Flex"
[ "$fam" = "$want" ] && echo "ok   pill $fam" || { echo "FAIL: pill font '$fam' (want '$want')"; exit 1; }
python3 -I - "$home/bar.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
assert im.size == (1100, 255), f"size {im.size}"
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
SCALE = 48 / 43
INK_SCALE = (SCALE / 1.5) ** 2
def dp(n): return int(n * SCALE + 0.5)
W, BH = 1100, 48
CW, BW = dp(230), dp(230) / 3
OFF = {"A": 0, "B": 85, "C": 170}  # A: idle; B: hover on glance; C: disconnected, 20 items
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)
def patch(cx, cy, r=1): return (cx - r, cy - r, cx + r + 1, cy + r + 1)

# 2. cluster surface and rounded outer corners
for lab, (x, y) in (("left", (20, BH - 10)), ("right", (W - 20, BH - 10))):
    box = (x, y, x + 6, y + 6)
    check(f"A {lab} cluster surface px", count(box, SURF, 3), 36, 36)
# Sample outside the scaled upper corner's arc, but inside its bounding box.
check("A left cluster corner is stage bg", int(near(im.getpixel((CW - dp(7), 3)), BG, 3)), 1, 1)
check("A right cluster corner is stage bg", int(near(im.getpixel((W - CW + dp(7), 3)), BG, 3)), 1, 1)

# 3. hover border: bottom dp(3) strip under the glance button, accent only in B
for lab in "AB":
    y = OFF[lab] + BH - dp(3)
    x0, x1 = dp(7), int(BW) - dp(7)
    n = count((x0, y, x1, y + dp(3)), ERR)
    if lab == "B": check("B glance border px", n, int(0.95 * (x1 - x0) * dp(3)))
    else: check("A glance border px", n, 0, 0)
y = OFF["B"] + BH - dp(3)
check("B other-button border px", count((int(BW) + dp(7), y, int(2 * BW) - dp(7), y + dp(3)), ERR), 0, 0)

# 4. dock: items are dp(35) wide, dp(4) apart, centred; the focused indicator
# is dp(6) x dp(3) at the item's bottom, dp(6) above the bar bottom.
iw, gap = dp(35), dp(4)
dx0 = (W - (3 * iw + 2 * gap)) / 2
ix = [int(dx0 + i * (iw + gap)) for i in range(3)]
ybot = BH - dp(6)                  # item bottom
band = lambda i: (ix[i] + iw // 2 - 5, ybot - dp(3) - 1, ix[i] + iw // 2 + 5, ybot)
item = lambda i: (ix[i], 0, ix[i] + iw, ybot)
b0 = (ix[0] + iw // 2 - 2, ybot - dp(3) + 1, ix[0] + iw // 2 + 3, ybot - 1)
check("A kitty indicator px (inversePrimary)", count(b0, INVP), int(0.9 * area(b0)))
accents = (ERR, SEC, TER, PRI, INVP, FGTC)
check("A firefox indicator-band accent px", sum(count(band(1), a) for a in accents), 0, 0)
check("A firefox glyph muted px (outline)", count(item(1), OUT), int(150 * INK_SCALE))
check("A firefox glyph accent px (tertiary)", count(item(1), TER), 0, 0)
check("A mpv glyph px (fgTertiaryContainer)", count(item(2), FGTC), int(100 * INK_SCALE))
check("A mpv indicator-band px", count(band(2), FGTC), 0, 0)

# 5. Battery sample points follow the scaled, centred icon/content row.
icon_width = dp(16)   # 12pt icon converted to pixels before bar scaling
bx = round(W - CW / 6 + (icon_width + dp(10)) / 2)
stack_gap = dp(8 / 3)
part_height = (dp(23) - 2 * stack_gap) / 3
stack = lambda lab, k: patch(bx, round(OFF[lab] + (BH - dp(23)) / 2 + part_height / 2 + k * (part_height + stack_gap)), 1)
half = tuple((a + b) // 2 for a, b in zip(FGTC, SURF))
for k in range(3):
    check(f"A battery part {k} full px", count(stack("A", k), FGTC), area(stack("A", k)))
check("B battery top empty px", count(stack("B", 0), HIGH), area(stack("B", 0)))
check("B battery middle half px", count(stack("B", 1), half), area(stack("B", 1)))
check("B battery bottom full px", count(stack("B", 2), FGTC), area(stack("B", 2)))

# 6. Signal bars share the same icon/content centering.
signal_width = 4 * dp(5) + 3 * dp(8 / 3)
signal_left = W - CW + CW / 6 + (icon_width + dp(10) - signal_width) / 2
sx = [round(signal_left + dp(5) / 2 + (dp(5) + dp(8 / 3)) * i) for i in range(4)]
def colh(lab, x, col):
    return sum(near(im.getpixel((x, y)), col) for y in range(OFF[lab], OFF[lab] + BH))
for i, x in enumerate(sx):
    mid = patch(x, OFF["A"] + BH // 2, 1)
    check(f"A signal bar {i} px (primary)", count(mid, PRI), area(mid))
    midb = patch(x, OFF["B"] + BH // 2, 1)
    want, nm = (PRI, "primary") if i < 2 else (HIGH, "container")
    check(f"B signal bar {i} px ({nm})", count(midb, want), area(midb))
hs = [colh("A", x, PRI) for x in sx]
print("signal bar heights", hs)
check("A signal heights strictly increase", int(all(a < b for a, b in zip(hs, hs[1:]))), 1, 1)

# 7. Volume-ring samples stay on the scaled stroke's centre line.
import math
rcx, rr = 5 * CW / 6 + (icon_width + dp(10)) / 2, (dp(23) - dp(5)) / 2
def ring(lab, deg):    # deg counter-clockwise from 12 o'clock
    t = math.radians(deg)
    return patch(int(round(rcx - rr * math.sin(t))), int(round(OFF[lab] + BH / 2 - rr * math.cos(t))), 0)
for deg in range(0, 360, 45):
    b = ring("A", deg)
    check(f"A ring {deg:3d} deg px (fgSurface)", count(b, FGS), area(b))
for deg in (20, 72, 124):
    b = ring("B", deg)
    check(f"B ring {deg:3d} deg px (muted arc)", count(b, OUT), area(b))
for deg in (180, 230, 290, 340):
    b = ring("B", deg)
    check(f"B ring {deg:3d} deg px (backdrop)", count(b, HIGH), area(b))

# 8. tray count: pill in A, slashed line in B (button 2 of the right cluster)
tray_x = W - CW / 2 + (icon_width + dp(10)) / 2
ab = lambda lab: (round(tray_x - dp(23) / 2), OFF[lab] + (BH - dp(23)) // 2, round(tray_x + dp(23) / 2), OFF[lab] + (BH + dp(23)) // 2)
check("A tray pill px (container)", count(ab("A"), HIGH), int(700 * INK_SCALE))
check("A tray slash px (tertiary)", count(ab("A"), TER), 0, 0)
check("B tray slash px (tertiary)", count(ab("B"), TER), int(0.6 * dp(23) * dp(4)))
check("B tray pill px (container)", count(ab("B"), HIGH), 0, 20)

# 10. Disconnected bars collapse to the scaled short height; battery parts
# remain empty, empty, half for the 10 % fixture.
for i, x in enumerate(sx):
    mid = patch(x, OFF["C"] + BH // 2, 1)
    check(f"C signal bar {i} px (muted)", count(mid, OUT), area(mid))
    check(f"C signal bar {i} height px", colh("C", x, OUT), dp(6) - 2, dp(6))
check("C battery top empty px", count(stack("C", 0), HIGH), area(stack("C", 0)))
check("C battery middle empty px", count(stack("C", 1), HIGH), area(stack("C", 1)))
check("C battery bottom half px", count(stack("C", 2), half), area(stack("C", 2)))

# 11. A long dock row stays clipped between the resized clusters and leaves
# the side margins and gaps between button content clear.
bgc = lambda box: sum(not near(im.getpixel((x, y)), BG, 3) for x in range(box[0], box[2]) for y in range(box[1], box[3]))
sfc = lambda box: sum(not near(im.getpixel((x, y)), SURF, 3) for x in range(box[0], box[2]) for y in range(box[1], box[3]))
yc0, yc1 = OFF["C"] + 3, OFF["C"] + BH - 3
fl, fr = CW + dp(8), W - CW - dp(8)
check("C dock ink left of free band px", bgc((CW, yc0, fl, yc1)), 0, 0)
check("C dock ink right of free band px", bgc((fr, yc0, W - CW, yc1)), 0, 0)
check("C dock ink in free band px", bgc((fl, yc0, fr, yc1)), int(400 * INK_SCALE))
check("C left cluster gap 1 px", sfc((dp(72) + 2, yc0, dp(81), yc1)), 0, 0)
check("C left cluster gap 2 px", sfc((dp(150) + 2, yc0, dp(157), yc1)), 0, 0)

if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("bottom bar render: ok")
PY
