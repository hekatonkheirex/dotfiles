// Copied to the root of a config copy by scripts/controls-render.sh.
// Renders the liquid-tile controls at fixed positions, saves $GOLDEN_OUT and
// prints "CHECK name x y r g b" lines (expected colors come from Colors) for
// the script to compare against the saved pixels.
import QtQuick
import Quickshell
import "config"
import "bar"
import "bar/controls"
import "bar/primitives"

ShellRoot {
  FloatingWindow {
    implicitWidth: 760
    implicitHeight: 560
    color: Colors.surface
    // Input-transparent so the real pointer cannot add a hover overlay.
    mask: Region {}

    Item {
      id: stage
      width: 760
      height: 560

      Rectangle { anchors.fill: parent; color: Colors.surface }

      function expect(name, x, y, c) {
        console.log("CHECK " + name + " " + x + " " + y + " "
          + Math.round(c.r * 255) + " " + Math.round(c.g * 255) + " " + Math.round(c.b * 255))
      }

      SwitchControl { x: 20; y: 20; width: 58; checked: true }
      SwitchControl { x: 100; y: 20; width: 58; checked: false }
      SliderControl { x: 20; y: 100; width: 400; value: 0.6 }
      IconButton { x: 20; y: 180; width: 48; height: 48; size: 40; iconLabel: "settings"; selected: true }
      ActionButton { x: 20; y: 240; width: 160; height: 48; labelText: "Pill"; variant: "pill" }
      LevelTile { x: 20; y: 320; value: 0.5; iconLabel: "settings" }
    }

    Timer {
      interval: 900
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        // Switch tracks are 58x30 centered in a 40px row: center is (x+29, y+20).
        stage.expect("switch-checked-track", 49, 40, Colors.primary)
        stage.expect("switch-unchecked-track", 129, 40, Colors.surfaceContainerHighest)
        stage.expect("slider-fill-30pct", 20 + 120, 120, Colors.primary)
        stage.expect("slider-empty-90pct", 20 + 360, 120, Colors.surfaceContainerHighest)
        // Button box is 48x48 at (20,180); 12px left of center is inside the
        // 29px white round and clear of the 18px glyph.
        stage.expect("icon-selected-white-round", 44 - 12, 204, Qt.color("#ffffff"))
        stage.expect("pill-left-end", 24, 264, Colors.primary)
        // x+10 stays clear of the 26px badge centered at the tile bottom.
        stage.expect("level-fill-25pct", 30, 320 + 58 * 0.75, Colors.primary)
        stage.expect("level-empty-85pct", 49, 320 + 58 * 0.15, Colors.surfaceContainerHighest)
        Qt.quit()
      })
    }
  }
}
