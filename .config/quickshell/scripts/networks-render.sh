#!/usr/bin/env bash
# Usage: networks-render.sh [quickshell-root]   (env NETWORKS_RENDER_ROOT overrides it;
# KEEP_DIR=path keeps a copy of the renders, even when the check fails)
# Renders NetworksContent under the elenapan palette in a scratch HOME
# (tests/networks/shell.qml): four fixture rows (a), passphrase row open with
# vpn on and scanning (b), forget confirmation (f) and an empty model (e).
# Runs the click/key checks and NetworkListService against fixture nmcli
# output (never the real nmcli), then pixel-checks row border colors per
# signal bucket, the connected row's solid border, button accents, the empty
# state, bandwidth and toolbar glyphs. Boxes come from the GEOM log lines.
set -euo pipefail
root=$(realpath "${NETWORKS_RENDER_ROOT:-${1:-$(dirname "$0")/..}}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share" "$home/run" "$home/out" "$home/fx"
chmod 700 "$home/run"
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/networks/shell.qml" "$home/cfg/shell.qml"
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts" "$home/.local/share/fonts"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
# Fixture nmcli output (terse, escaped) for the service checks.
printf '%s\n' 'yes:HomeNet:90:WPA2' 'no:Cafe\:Guest:60:' 'no:Weak:10:WPA2' 'no::40:WPA2' 'no:HomeNet:50:WPA2' > "$home/fx/list.txt"
printf '%s\n' 'HomeNet:802-11-wireless:yes:wlp3s0' 'Weak:802-11-wireless:yes:' 'Wired:802-3-ethernet:yes:enp4s0' > "$home/fx/saved.txt"
printf '%s\n' 'enp4s0:ethernet:connected' 'wlp3s0:wifi:connected' 'lo:loopback:unmanaged' > "$home/fx/device.txt"
printf '%s\n' 'PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.' '64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=12.4 ms' \
  '--- 1.1.1.1 ping statistics ---' 'rtt min/avg/max/mdev = 11.0/12.6/14.2/1.0 ms' > "$home/fx/ping.txt"
printf '%s\n' 'ping: connect: Network is unreachable' > "$home/fx/ping-unreachable.txt"
HOME="$home" XDG_RUNTIME_DIR="$home/run" RENDER_DIR="$home/out" NETWORKS_FIXTURES="$home/fx" QS_NO_RELOAD_POPUP=1 \
  timeout 60 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -z "${KEEP_DIR:-}" ] || { mkdir -p "$KEEP_DIR"; cp "$home"/out/*.png "$KEEP_DIR"/ 2>/dev/null || true; }
[ -s "$home/out/a.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor|WARN'
errs=$(grep -E "$errpat" "$home/qs.log" | grep -Ev 'got operation finished from dropped operation|QWaylandTextInputv3::(disableSurface|enableSurface)' | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -E 'PASS ' "$home/qs.log" | sed 's/.*PASS /ok   /'
qml_ok=1
grep -q 'DONE networks 0 fail' "$home/qs.log" || { qml_ok=0; grep -E 'FAIL |DONE' "$home/qs.log" | sed 's/.*\(FAIL \|DONE\)/\1/' || tail -20 "$home/qs.log"; }
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
X = {n: C[f"x{n}"] for n in (1, 2, 3, 4, 5, 8)}
SURF, CONT = C["surface"], C["surfaceContainer"]
imgs = {}
def im(name):
    if name not in imgs: imgs[name] = Image.open(f"{out}/{name}.png").convert("RGB")
    return imgs[name]
def near(a, b, t=8): return all(abs(a[i] - b[i]) <= t for i in range(3))
def box(img, name):
    x, y, w, h = G[(img, name)]
    return (x, y, x + w, y + h)
def count(img, b, col, t=8):
    p = im(img)
    return sum(near(p.getpixel((x, y)), col, t) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
def ink(img, b, bg):
    p = im(img)
    return sum(not near(p.getpixel((x, y)), bg, 3) for x in range(b[0], b[2]) for y in range(b[1], b[3]))
checks = []
def check(name, n, lo, hi=None):
    ok = n >= lo and (hi is None or n <= hi)
    print(f"{'ok  ' if ok else 'FAIL'} {name}: {n} (want {lo}..{hi if hi is not None else 'inf'})")
    checks.append(ok)

# (a) Border per signal bucket (spec: excellent, good x4; ok x3; bad x8).
# Fixture signals 90, 60, 30, 10. Row 0 is connected: solid border; the
# others dotted (about half the box).
BUCKET = [4, 4, 3, 8]
for i, n in enumerate(BUCKET):
    b = box("a", f"border_{i}")
    area = (b[2] - b[0]) * (b[3] - b[1])
    hit = count("a", b, X[n])
    others = sum(count("a", b, X[m], 4) for m in (1, 2, 3, 4, 8) if X[m] != X[n])
    check(f"a: row {i} border is x{n} (no other accent)", others, 0, 3)
    if i == 0:
        check("a: connected row border solid (% of box)", round(100 * hit / area), 90)
    else:
        check(f"a: row {i} border dotted (% of box)", round(100 * hit / area), 30, 70)
# Buttons: connect x2 (rows 1,2,3), disconnect x1 (row 0), forget x3 (rows 0,3).
BTN = {"connect": (2, [1, 2, 3]), "disconnect": (1, [0]), "forget": (3, [0, 3])}
for kind, (n, rows) in BTN.items():
    found = sorted(int(k[1].split("_")[1]) for k in G if k[0] == "a" and k[1].startswith(kind + "_"))
    check(f"a: {kind} buttons on rows {rows}", int(found == rows), 1, 1)
    for r in found:
        check(f"a: {kind} button row {r} glyph x{n} px", count("a", box("a", f"{kind}_{r}"), X[n]), 10)
# Bandwidth: down glyph x1, up glyph x2, text ink.
check("a: bandwidth down glyph x1 px", count("a", box("a", "bandDownSymbol"), X[1]), 20)
check("a: bandwidth up glyph x2 px", count("a", box("a", "bandUpSymbol"), X[2]), 20)
for t in ("bandDownText", "bandUpText"):
    check(f"a: {t} ink px", ink("a", box("a", t), SURF), 80)
# Toolbar glyph accents: vpn off x8, scan x2, speedtest x5, ping x3.
for tool, n in (("tool_vpn", 8), ("tool_scan", 2), ("tool_speed", 5), ("tool_ping", 3)):
    check(f"a: {tool} glyph x{n} px", count("a", box("a", tool + "_symbol"), X[n]), 15)
    check(f"a: {tool} label ink px", ink("a", box("a", tool + "_label"), CONT), 30)
# (b) vpn on: x4; scanning: loading glyph x8.
check("b: vpn on glyph x4 px", count("b", box("b", "tool_vpn_symbol"), X[4]), 15)
check("b: scanning glyph x8 px", count("b", box("b", "tool_scan_symbol"), X[8]), 15)
check("b: scanning glyph not x2 px", count("b", box("b", "tool_scan_symbol"), X[2], 4), 0, 3)
check("b: masked passphrase ink px", ink("b", box("b", "passInput"), CONT), 20)
# (f) Forget confirmation: yes x1, no x8 labels drawn.
check("f: yes label x1 px", count("f", box("f", "forgetYes"), X[1]), 15)
check("f: no label x8 px", count("f", box("f", "forgetNo"), X[8]), 15)
# (e) Empty state in x8.
check("e: empty text x8 px", count("e", box("e", "emptyText"), X[8]), 60)
check("e: empty symbol x8 px", count("e", box("e", "emptySymbol"), X[8]), 60)

if not all(checks):
    print(f"FAIL: {checks.count(False)} of {len(checks)} checks")
    sys.exit(1)
print("networks render: ok")
PY
[ "$qml_ok" = 1 ] && [ "$pix_ok" = 1 ] || { echo "FAIL: networks render"; exit 1; }
