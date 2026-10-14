#!/usr/bin/env bash
# Usage: sidebar-render.sh [quickshell-root]   (env SIDEBAR_RENDER_ROOT overrides it;
# KEEP_PNG=path keeps a copy of the render, even when the check fails)
# Renders the Home, Agenda and Media pages and the page indicators with fixed
# inputs under the elenapan palette in a scratch HOME (tests/sidebar/shell.qml),
# fails on any QML error in the log, runs the keyboard paging checks, and
# pixel-checks tile fills, the week strip, the calendar, the media ring, the
# seek line and the indicator pills. Boxes come from the GEOM log lines.
set -euo pipefail
root=$(realpath "${SIDEBAR_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share" "$home/run"
chmod 700 "$home/run"
# qs runtime files stay out of /run/user; the compositor socket is linked in.
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/sidebar/shell.qml" "$home/cfg/shell.qml"
# The fontconfig rules naming the icon files ElenaIcons1..3 live in the real
# config dir; the whole user font dir brings icomoon, Baro (clock) and Kyok.
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts" "$home/.local/share/fonts"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" XDG_RUNTIME_DIR="$home/run" GOLDEN_OUT="$home/sidebar.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/sidebar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/sidebar.png" "$KEEP_PNG"
# Excluded: mpris absent in scratch session; WARNs that fire in every scratch
# run (FileView op finished after drop, wayland text-input enable/disableSurface).
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'Cannot find the mpris|org\.mpris|got operation finished from dropped operation|QWaylandTextInputv3::(disableSurface|enableSurface)' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -q 'DONE sidebar 0 fail' "$home/qs.log" || { grep -E 'PASS |FAIL |DONE' "$home/qs.log" || tail -20 "$home/qs.log"; exit 1; }
grep -E 'PASS ' "$home/qs.log" | sed 's/.*PASS /ok   /'
grep -o 'GEOM .*' "$home/qs.log" > "$home/geom.txt"
python3 -I - "$home/sidebar.png" "$home/geom.txt" <<'PY'
import math, sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
assert im.size == (1800, 831), f"size {im.size}"
G = {}
for line in open(sys.argv[2]):
    _, name, x, y, w, h = line.split()
    G[name] = tuple(int(v) for v in (x, y, w, h))
def hx(s): return tuple(int(s[i:i+2], 16) for i in (1, 3, 5))
SURF, HIGH, ERR = hx("#1a1f2b"), hx("#343c4d"), hx("#ff6b6b")
SEC, INVP, OUT, FGS = hx("#f06292"), hx("#8e4f90"), hx("#5b6578"), hx("#f2f4f8")
FGTC = hx("#cfeefa")
def mix(a, b, t): return tuple(round(a[i] * t + b[i] * (1 - t)) for i in range(3))
def near(a, b, t=8): return all(abs(a[i] - b[i]) <= t for i in range(3))
def count(box, col, t=8):
    x0, y0, x1, y1 = box
    return sum(near(im.getpixel((x, y)), col, t) for x in range(x0, x1) for y in range(y0, y1))
def ink(box):
    x0, y0, x1, y1 = box
    return sum(not near(im.getpixel((x, y)), SURF, 3) for x in range(x0, x1) for y in range(y0, y1))
def area(box): return (box[2] - box[0]) * (box[3] - box[1])
def dp(n): return int(n * 1.5 + 0.5)
def patch(cx, cy, r=2): return (cx - r, cy - r, cx + r + 1, cy + r + 1)
def runs(y, x0, x1, pred):
    out, start = [], None
    for x in range(x0, x1 + 1):
        on = x < x1 and pred(im.getpixel((x, y)))
        if on and start is None: start = x
        if not on and start is not None: out.append((start, x - start)); start = None
    return out
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)

# 1. Home. Tile trough is dp(64) centred in a dp(76) cell; the cpu tile is 50 %.
def trough(name):
    x, y, w, h = G[name]
    s = dp(64)
    return x + (w - s) // 2, y + (h - s) // 2, s
tx, ty, s = trough("tile_cpu")
cx = tx + s // 3                 # left of the round label at the bottom-right
check("cpu tile 25 % height is trough", count(patch(cx, ty + s // 4), HIGH), 25, 25)
check("cpu tile 75 % height is fill (x2)", count(patch(cx, ty + 3 * s // 4), SEC), 25, 25)
tx, ty, s = trough("tile_volume")
check("muted volume fill is x8 #5b6578", count(patch(tx + s // 3, ty + 3 * s // 4), OUT), 25, 25)
check("muted volume fill has no x5", count(patch(tx + s // 3, ty + 3 * s // 4), INVP), 0, 0)
x, y, w, h = G["weekStrip"]
cw = dp(36)
gap = (w - 7 * cw) // 6
check("week strip 12 S clear of the page edges", min(x, 450 - (x + w)), dp(12))
hl = [count((x + i * (cw + gap) + 4, y + 4, x + i * (cw + gap) + cw - 4, y + h - 4), HIGH) for i in range(7)]
print("week strip highlight px", hl)
check("week strip highlighted days", sum(1 for n in hl if n > 300), 1, 1)
check("week strip highlight is Wednesday (index 3)", int(hl.index(max(hl))), 3, 3)

x, y, w, h = G["weatherPill"]
disc = (x, y, x + h, y + h)
check("weather disc fgSurface px", count(disc, FGS), int(0.45 * area(disc)))
check("weather temp + description ink px", sum(not near(im.getpixel((i, j)), HIGH, 6) and not near(im.getpixel((i, j)), SURF, 6)
      for i in range(x + h + 2, x + w - 2) for j in range(y + 3, y + h - 3)), 150)
check("weather separator dot px (x8)", count((x, y, x + w, y + h), OUT, 10), 25)
check("weather description ink px (right half)", sum(not near(im.getpixel((i, j)), HIGH, 6)
      for i in range(x + w // 2, x + w - dp(7)) for j in range(y + 3, y + h - 3)), 60)

# 2. Agenda: today's filled round, dimmed leading day, empty-state ink.
x, y, w, h = G["todayCell"]
check("today round fgSurface px", count((x, y, x + w, y + h), FGS), 600)
x, y, w, h = G["dayCell0"]
# Small text at half opacity has few solid pixels: require ink, and that the
# brightest pixel is the outline-at-0.5 blend, not full outline.
dim = mix(OUT, SURF, 0.5)
box = (x, y, x + w, y + h)
check("leading day 27 ink px", ink(box), 30)
top = max((im.getpixel((i, j)) for i in range(box[0], box[2]) for j in range(box[1], box[3])), key=sum)
check("leading day 27 brightest px is outline at 0.5", int(near(top, dim, 8)), 1, 1)
check("leading day 27 full outline px", count(box, OUT, 6), 0, 3)
x, y, w, h = G["taskList"]
check("empty task list ink px", ink((x, y, x + w, y + h)), 150)

# 3. Media: half ring along the bottom, filled from the left end.
x, y, w, h = G["artRing"]
rcx, rcy, rr = x + w / 2, y + h / 2, dp(80) + dp(9)
def arc(frac):   # fraction along the bottom half from the left end
    t = math.pi - math.pi * frac
    return patch(int(round(rcx + rr * math.cos(t))), int(round(rcy + rr * math.sin(t))), 1)
for f in (0.05, 0.15, 0.2):
    check(f"ring {int(f * 100)} % fill px (x5)", count(arc(f), INVP), 9, 9)
for f in (0.35, 0.6, 0.9):
    check(f"ring {int(f * 100)} % backdrop px", count(arc(f), HIGH), 9, 9)
check("ring top half empty px", ink((x, y, x + w, y + int(h / 2) - dp(80) - 2)) , 0, 0)
x, y, w, h = G["seekLine"]
yc = y + h // 2
lit = runs(yc, x, x + w, lambda p: near(p, INVP))
dark = runs(yc, x, x + w, lambda p: near(p, HIGH))
check("seek line colored lines", len(lit), 5, 5)
check("seek line muted lines", len(dark), 15, 15)
check("colored lines are the leftmost", int(max(s for s, _ in lit) < min(s for s, _ in dark)), 1, 1)
x, y, w, h = G["playButton"]
inner = patch(x + w // 2, y + h // 2, dp(8))
check("play glyph ink px", ink(inner), 60)
top = max((im.getpixel((i, j)) for i in range(inner[0], inner[2]) for j in range(inner[1], inner[3])), key=sum)
check("play glyph brightest px is x6 (playing)", int(near(top, FGTC, 12)), 1, 1)
check("play button disc px (surface)", count(inner, SURF), 150)
# Gameboy cross: arms are x0 around the play disc; B (stop) sits 20 S below A.
for nm in ("prevButton", "nextButton", "volumeUpButton", "volumeDownButton"):
    x, y, w, h = G[nm]
    check(f"{nm} arm x0 px", count((x + 2, y + 2, x + w - 2, y + h - 2), HIGH), int(0.3 * (w - 4) * (h - 4)))
check("prev/next arms meet (pair width 100 S)", G["nextButton"][0] + G["nextButton"][2] - G["prevButton"][0], dp(100) - 1, dp(100) + 1)
check("volume arms stack (pair height 100 S)", G["volumeDownButton"][1] + G["volumeDownButton"][3] - G["volumeUpButton"][1], dp(100) - 1, dp(100) + 1)
check("B button 20 S below A", G["stopButton"][1] - G["favoriteButton"][1], dp(20) - 1, dp(20) + 1)
check("A button right of B", int(G["favoriteButton"][0] > G["stopButton"][0]), 1, 1)

# 4. Indicators at page 1: 21, 41, 21 px pills; x2 selected, the rest at 0.3.
x, y, w, h = G["pageDots"]
yc = y + h // 2
pills = runs(yc, x - 2, x + w + 2, lambda p: not near(p, SURF, 3))
print("pills", pills)
check("indicator pill count", len(pills), 3, 3)
if len(pills) == 3:
    wid = [n for _, n in pills]
    check("unselected pill 0 width", wid[0], dp(14) - 1, dp(14) + 1)
    check("selected pill width (27 S)", wid[1], dp(27) - 1, dp(27) + 1)
    check("unselected pill 2 width", wid[2], dp(14) - 1, dp(14) + 1)
    mid = lambda i: im.getpixel((pills[i][0] + pills[i][1] // 2, yc))
    check("selected pill is x2 #f06292", int(near(mid(1), SEC)), 1, 1)
    check("pill 0 is x1 at 0.3", int(near(mid(0), mix(ERR, SURF, 0.3))), 1, 1)
    check("pill 2 is x5 at 0.3", int(near(mid(2), mix(INVP, SURF, 0.3))), 1, 1)

if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("sidebar render: ok")
PY
