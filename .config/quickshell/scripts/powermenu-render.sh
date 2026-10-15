#!/usr/bin/env bash
# Usage: powermenu-render.sh [quickshell-root]   (env POWERMENU_RENDER_ROOT overrides it;
# KEEP_DIR=path keeps a copy of the renders, even when the check fails)
# Renders PowerMenuContent under the elenapan palette in a scratch HOME
# (tests/power-menu/shell.qml): revealed, revealed with reboot selected, and
# locked at five ring states, plus the full lock surface (LockSurfaceContent)
# driven by typed keys. Fails on any QML error in the log, runs the
# hover/keyboard/mask checks in QML, and pixel-checks the six button glyph
# colors, hover dimming, the palette row, the terminal line and the lock ring
# border per last action. Boxes come from the GEOM log lines.
set -euo pipefail
root=$(realpath "${POWERMENU_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share" "$home/run" "$home/out"
chmod 700 "$home/run"
# qs runtime files stay out of /run/user; the compositor socket is linked in.
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/power-menu/shell.qml" "$home/cfg/shell.qml"
# Icon files ElenaIcons1..3 come from the real fontconfig rules; the user font
# dir brings icomoon and Battle Andy.
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts" "$home/.local/share/fonts"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" XDG_RUNTIME_DIR="$home/run" RENDER_DIR="$home/out" QS_NO_RELOAD_POPUP=1 \
  timeout 40 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -z "${KEEP_DIR:-}" ] || { mkdir -p "$KEEP_DIR"; cp "$home"/out/*.png "$KEEP_DIR"/ 2>/dev/null || true; }
[ -s "$home/out/a.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'got operation finished from dropped operation|QWaylandTextInputv3::(disableSurface|enableSurface)' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -E 'PASS ' "$home/qs.log" | sed 's/.*PASS /ok   /'
# QML-side failures are reported, then the pixel checks still run.
qml_ok=1
grep -q 'DONE powermenu 0 fail' "$home/qs.log" || { qml_ok=0; grep -E 'FAIL |DONE' "$home/qs.log" | sed 's/.*\(FAIL \|DONE\)/\1/' || tail -20 "$home/qs.log"; }
grep -o 'GEOM .*' "$home/qs.log" > "$home/geom.txt"
pix_ok=1
python3 -I - "$home/out" "$home/geom.txt" <<'PY' || pix_ok=0
import sys
from PIL import Image, ImageChops
out = sys.argv[1]
G = {}
for line in open(sys.argv[2]):
    _, img, name, x, y, w, h = line.split()
    G[(img, name)] = tuple(int(v) for v in (x, y, w, h))
imgs = {}
def im(name):
    if name not in imgs:
        image = Image.open(f"{out}/{name}.png").convert("RGBA")
        if name.startswith("pill-"):
            image = Image.alpha_composite(Image.new("RGBA", image.size, (*SURF, 255)), image)
        imgs[name] = image.convert("RGB")
    return imgs[name]
def hx(s): return tuple(int(s[i:i+2], 16) for i in (1, 3, 5))
SURF, OUT, OUTV, FGS = hx("#1a1f2b"), hx("#5b6578"), hx("#3a4254"), hx("#f2f4f8")
X = {1: hx("#ff6b6b"), 2: hx("#f06292"), 3: hx("#5bb8d4"), 4: hx("#c77dc8"), 5: hx("#8e4f90"), 6: hx("#cfeefa"), 8: OUT}
def mix(a, b, t): return tuple(round(a[i] * t + b[i] * (1 - t)) for i in range(3))
def near(a, b, t=8): return all(abs(a[i] - b[i]) <= t for i in range(3))
def box(img, name):
    x, y, w, h = G[(img, name)]
    return (x, y, x + w, y + h)
def count(img, b, col, t=8):
    p = im(img)
    return sum(near(p.getpixel((x, y)), col, t) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
def ink(img, b):
    p = im(img)
    return sum(not near(p.getpixel((x, y)), SURF, 3) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
def patch(cx, cy, r=2): return (cx - r, cy - r, cx + r + 1, cy + r + 1)
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)

# Button order and accent slots (the spec table, not the model).
BUTTONS = [("poweroff", 1), ("reboot", 2), ("exit", 4), ("hibernate", 6), ("suspend", 3), ("lock", 5)]
# (a) Revealed, nothing selected: each glyph is drawn in its accent.
for bid, n in BUTTONS:
    b = box("a", "button_" + bid)
    check(f"a: {bid} glyph x{n} px", count("a", b, X[n]), 40)
    others = sum(count("a", b, X[m], 4) for m in (1, 2, 3, 4, 5, 6) if X[m] != X[n])
    check(f"a: {bid} glyph has no other accent", others, 0, 3)
# (b) Reboot selected: reboot full, the other five at 0.3 over surface.
for bid, n in BUTTONS:
    b = box("b", "button_" + bid)
    if bid == "reboot":
        check("b: reboot glyph stays full x2", count("b", b, X[n]), 40)
    else:
        check(f"b: {bid} glyph full-color px", count("b", b, X[n], 4), 0, 3)
        check(f"b: {bid} glyph dimmed (0.3) px", count("b", b, mix(X[n], SURF, 0.3), 6), 40)
# (c) Palette row x1, x3, x2, x6, x4, x5.
for i, n in enumerate([1, 3, 2, 6, 4, 5]):
    x, y, w, h = G[("a", f"palette_{i}")]
    check(f"a: palette circle {i} is x{n}", count("a", patch(x + w // 2, y + h // 2), X[n]), 25, 25)
# (d) Terminal: "$ reboot" draws ink in the value box (text checked in QML).
check("b: terminal value ink px", ink("b", box("b", "terminalValue")), 150)
check("a: terminal value empty", ink("a", box("a", "terminalValue")), 0, 0)
# (e) Lock ring border by last action.
RING = [("0_clear", OUTV), ("1_insert", X[1]), ("2_insert", X[3]), ("1_delete", X[8]), ("2_delete", mix(OUT, SURF, 0.3))]
for tag, col in RING:
    img = "ring_" + tag
    x, y, w, h = G[(img, "lockRing")]
    bw = round(6 * 1.5)
    px = [patch(x + bw // 2, y + h // 2, 1), patch(x + w - 1 - bw // 2, y + h // 2, 1), patch(x + w // 2, y + bw // 2, 1)]
    check(f"ring {tag} border px", sum(count(img, p, col, 6) for p in px), 27, 27)
check("locked: glyph ink inside the ring", ink("ring_0_clear", box("ring_0_clear", "lockGlyph")), 200)
# (g) Full lock surface after typing "abc" then backspace: opaque surface
# backdrop, ring x2 (third insert) then outline 0.3 (delete at 2).
for img, col in (("s_3_insert", X[2]), ("s_2_delete", mix(OUT, SURF, 0.3))):
    x, y, w, h = G[(img, "lockRing")]
    bw = round(6 * 1.5)
    px = [patch(x + bw // 2, y + h // 2, 1), patch(x + w - 1 - bw // 2, y + h // 2, 1), patch(x + w // 2, y + bw // 2, 1)]
    check(f"surface {img} ring border px", sum(count(img, p, col, 6) for p in px), 27, 27)
    W, H = im(img).size
    check(f"surface {img} backdrop is opaque surface", sum(count(img, patch(cx, cy), SURF, 2) for cx, cy in ((4, 4), (W - 5, H - 5))), 50, 50)

# Pills: the hovered pill fills solid, the other and the resting state stay
# outlines, and leaving restores the resting capture.
normal, red, blue, restored = (im("pill-" + state) for state in ("normal", "red", "blue", "restored"))
check("pill captures keep identical bounds", int(normal.size == red.size == blue.size == restored.size), 1, 1)
w, h = normal.size
def centre(fx):
    cx, cy = round(fx * w / 64), round(h / 2)
    return (cx - 2, cy - 2, cx + 3, cy + 3)
RED, BLUE = centre(15), centre(49)
def count_in(image, b, col, t=8):
    return sum(near(image.getpixel((x, y)), col, t) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
check("resting red pill is hollow", count_in(normal, RED, X[1]), 0, 0)
check("resting blue pill is hollow", count_in(normal, BLUE, X[3]), 0, 0)
check("hovered red pill fills red", count_in(red, RED, X[1]), 25, 25)
check("hovering red leaves blue hollow", count_in(red, BLUE, X[3]), 0, 0)
check("hovered blue pill fills blue", count_in(blue, BLUE, X[3]), 25, 25)
check("hovering blue leaves red hollow", count_in(blue, RED, X[1]), 0, 0)
check("leaving the pills restores the resting capture",
      sum(pixel != (0, 0, 0) for pixel in ImageChops.difference(normal, restored).get_flattened_data()), 0, 0)

if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("powermenu render: ok")
PY
[ "$qml_ok" = 1 ] && [ "$pix_ok" = 1 ] || { echo "FAIL: powermenu render"; exit 1; }
