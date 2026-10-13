#!/usr/bin/env bash
# Usage: bar-font-check.sh [quickshell-root]
# Env: FONT_NEG_CONTROL=1 sets BottomBarFonts.family to ElenaIcons2 only in the
# scratch copy; the glyphs that live only in icomoon-feather.ttf must then FAIL.
# Renders the bottom bar glyphs (192 px, 4x the bar size, so rasterizer edge
# noise stays below the threshold) with a QML Text using BottomBarFonts.family
# (fontconfig appends ElenaIcons2 and 3 as per-glyph fallback), and with PIL
# straight from the file that owns each codepoint: the first of icomoon-feather.ttf, remix.ttf, iconic.ttf whose charset has it
# (Pango's per-glyph fallback order in the icomoon family). Compares ink masks
# (IoU >= 0.85 per glyph). Fails when fewer than three ElenaIcons families are
# installed or when Qt resolves a glyph from another file.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
real_home=$HOME
fdir="$real_home/.local/share/fonts/icomoon"
for f in icomoon-feather.ttf remix.ttf iconic.ttf; do
  [ -f "$fdir/$f" ] || { echo "FAIL: $fdir/$f missing"; exit 1; }
done
nfam=$(fc-list | grep -c 'ElenaIcons[123]:' || true)
[ "$nfam" -ge 3 ] || { echo "FAIL: only $nfam ElenaIcons families installed (need 3); run fc-cache -f $fdir"; exit 1; }
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share/fonts" "$home/run"
chmod 700 "$home/run"
# qs runtime files stay out of /run/user; the compositor socket is linked in.
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$home/cfg/"
if [ -n "${FONT_NEG_CONTROL:-}" ]; then
  # fontconfig only appends ElenaIcons2/3 for ElenaIcons1 requests, so asking
  # for ElenaIcons2 alone loses the fallback chain.
  sed -i 's|readonly property string family: .*|readonly property string family: "ElenaIcons2"|; s|readonly property var families: .*|readonly property var families: ["ElenaIcons2"]|' "$home/cfg/config/BottomBarFonts.qml"
fi
ln -s "$fdir" "$home/.local/share/fonts/icomoon"
# The scan rules naming the files ElenaIcons1..3 live in the real fontconfig dir.
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
cat > "$home/cfg/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "config"

ShellRoot {
  FloatingWindow {
    implicitWidth: 11 * 256
    implicitHeight: 256
    color: "black"
    mask: Region {}
    Row {
      id: stage
      Repeater {
        model: [0xE92B, 0xE982, 0xE943, 0xEE50, 0xEC79, 0xED38, 0xE9A0, 0xE934, 0xEEF5, 0xEB84, 0xED28]
        Item {
          width: 256; height: 256
          Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(modelData)
            color: "white"
            font.family: BottomBarFonts.family
            font.pixelSize: 192
            // FreeType glyphs like the PIL reference; distance-field text is
            // bolder and would blur the file comparison.
            renderType: Text.NativeRendering; font.hintingPreference: Font.PreferNoHinting
          }
        }
      }
    }
    Timer {
      interval: 1500; running: true
      onTriggered: stage.grabToImage(function(r) {
        console.log("families=" + JSON.stringify(BottomBarFonts.families) + " saved=" + r.saveToFile(Quickshell.env("FONT_OUT")))
        Qt.quit()
      })
    }
  }
}
QML
HOME="$home" XDG_RUNTIME_DIR="$home/run" FONT_OUT="$home/qt.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/qt.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
grep -o 'families=.*' "$home/qs.log" | head -1
python3 -I - "$home/qt.png" "$fdir" <<'PY'
import subprocess, sys
from PIL import Image, ImageChops, ImageDraw, ImageFont
cps = [0xE92B, 0xE982, 0xE943, 0xEE50, 0xEC79, 0xED38, 0xE9A0, 0xE934, 0xEEF5, 0xEB84, 0xED28]
order = ["icomoon-feather.ttf", "remix.ttf", "iconic.ttf"]
fdir = sys.argv[2]
def charset(f):
    out = subprocess.run(["fc-query", "-f", "%{charset}\n", f"{fdir}/{f}"], capture_output=True, text=True, check=True).stdout
    s = set()
    for part in out.split():
        a, _, b = part.partition("-")
        s.update(range(int(a, 16), int(b or a, 16) + 1))
    return s
sets = {f: charset(f) for f in order}
qt = Image.open(sys.argv[1]).convert("L")
def mask(img):
    m = img.point(lambda v: 255 if v > 96 else 0)
    box = m.getbbox()
    if box is None: return None
    return m.crop(box).resize((64, 64))
bad = 0
for i, cp in enumerate(cps):
    src = next((f for f in order if cp in sets[f]), None)
    a = mask(qt.crop((i * 256, 0, (i + 1) * 256, 256)))
    if src is None:
        iou, src = 0.0, "none"
    else:
        ref = Image.new("L", (256, 256), 0)
        ImageDraw.Draw(ref).text((128, 128), chr(cp), font=ImageFont.truetype(f"{fdir}/{src}", 192), fill=255, anchor="mm")
        b = mask(ref)
        if a is None or b is None:
            iou = 0.0
        else:
            # Best of a +-1 px shift: bbox crops differ by a pixel between rasterizers.
            pa = list(a.get_flattened_data())
            iou = 0.0
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    pb = list(ImageChops.offset(b, dx, dy).get_flattened_data())
                    inter = sum(1 for x, y in zip(pa, pb) if x and y)
                    union = sum(1 for x, y in zip(pa, pb) if x or y)
                    iou = max(iou, inter / union if union else 0.0)
    ok = iou >= 0.85
    bad += not ok
    print(f"{'ok  ' if ok else 'FAIL'} U+{cp:04X} iou {iou:.3f} from {src}")
sys.exit(1 if bad else 0)
PY
