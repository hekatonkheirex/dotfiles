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
    id: win
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
      SliderControl { x: 20; y: 100; value: 0.6 }
      IconButton { x: 20; y: 180; width: 48; height: 48; size: 40; iconLabel: "settings"; selected: true }
      ActionButton { x: 20; y: 240; width: 160; height: 48; labelText: "Pill"; variant: "pill" }
    }

    Timer {
      interval: 900
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        // Switch tracks are 58x30 centered in a 40px row: center is (x+29, y+20).
        stage.expect("switch-checked-track", 49, 40, Colors.primary)
        stage.expect("switch-unchecked-track", 129, 40, Colors.surfaceContainerHighest)
        stage.expect("slider-fill-below-level", 20 + 24, 100 + 46, Colors.primary)
        stage.expect("slider-empty-above-level", 20 + 24, 100 + 8, Colors.surfaceContainerHighest)
        // Button box is 48x48 at (20,180); 12px left of center is inside the
        // 29px white round and clear of the 18px glyph.
        stage.expect("icon-selected-white-round", 44 - 12, 204, Qt.color("#ffffff"))
        stage.expect("pill-left-end", 24, 264, Colors.primary)
        // Diagonal of the corner: inside a radius-20 arc, outside the radius-24 one. Only a
        // fully round end leaves this pixel on the surface.
        stage.expect("pill-corner-round", 26, 246, Colors.surface)
        Qt.quit()
      })
    }
  }
}
