#!/usr/bin/env bash
# Usage: bar-font-check.sh [quickshell-root]
# Renders the bottom bar glyphs with a QML Text using BottomBarFonts.family and
# with PIL straight from remix.ttf, then compares ink masks (IoU >= 0.85 per
# glyph). Fails when Qt resolves the shared "icomoon" family to another file.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
real_home=$HOME
font="$real_home/.local/share/fonts/icomoon/remix.ttf"
[ -f "$font" ] || { echo "FAIL: $font missing"; exit 1; }
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share/fonts"
cp -r "$root/config" "$home/cfg/"
ln -s "$real_home/.local/share/fonts/icomoon" "$home/.local/share/fonts/icomoon"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
cat > "$home/cfg/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "config"

ShellRoot {
  FloatingWindow {
    implicitWidth: 11 * 96
    implicitHeight: 96
    color: "black"
    mask: Region {}
    Row {
      id: stage
      Repeater {
        model: [0xE92B, 0xE982, 0xE943, 0xEE50, 0xEC79, 0xED38, 0xE9A0, 0xE934, 0xEEF5, 0xEB84, 0xED28]
        Item {
          width: 96; height: 96
          Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(modelData)
            color: "white"
            font.family: BottomBarFonts.family
            font.pixelSize: 48
          }
        }
      }
    }
    Timer {
      interval: 1500; running: true
      onTriggered: stage.grabToImage(function(r) {
        console.log("family=" + BottomBarFonts.family + " saved=" + r.saveToFile(Quickshell.env("FONT_OUT")))
        Qt.quit()
      })
    }
  }
}
QML
HOME="$home" FONT_OUT="$home/qt.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/qt.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
grep -o 'family=.*' "$home/qs.log" | head -1
python3 -I - "$home/qt.png" "$font" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont
cps = [0xE92B, 0xE982, 0xE943, 0xEE50, 0xEC79, 0xED38, 0xE9A0, 0xE934, 0xEEF5, 0xEB84, 0xED28]
qt = Image.open(sys.argv[1]).convert("L")
font = ImageFont.truetype(sys.argv[2], 48)
def mask(img):
    m = img.point(lambda v: 255 if v > 96 else 0)
    box = m.getbbox()
    if box is None: return None
    return m.crop(box).resize((64, 64))
bad = 0
for i, cp in enumerate(cps):
    a = mask(qt.crop((i * 96, 0, (i + 1) * 96, 96)))
    ref = Image.new("L", (96, 96), 0)
    ImageDraw.Draw(ref).text((48, 48), chr(cp), font=font, fill=255, anchor="mm")
    b = mask(ref)
    if a is None or b is None:
        iou = 0.0
    else:
        pa, pb = a.get_flattened_data(), b.get_flattened_data()
        inter = sum(1 for x, y in zip(pa, pb) if x and y)
        union = sum(1 for x, y in zip(pa, pb) if x or y)
        iou = inter / union if union else 0.0
    ok = iou >= 0.85
    bad += not ok
    print(f"{'ok  ' if ok else 'FAIL'} U+{cp:04X} iou {iou:.3f}")
sys.exit(1 if bad else 0)
PY
