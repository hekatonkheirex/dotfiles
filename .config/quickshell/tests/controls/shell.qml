// Copied to the root of a config copy by scripts/controls-render.sh.
// Renders the liquid-tile controls at fixed positions, saves $GOLDEN_OUT and
// prints "CHECK name x y r g b" lines (expected colors come from Colors) for
// the script to compare against the saved pixels.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar"
import "bar/controls"
import "bar/primitives"

ShellRoot {
  FloatingWindow {
    id: win
    property int badgeClicks: 0
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
      LevelTile {
        id: tile
        x: 20; y: 320; value: 0.5; iconLabel: "settings"; accessibleName: "Test level"
        onIconClicked: win.badgeClicks++
      }
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
        // Diagonal of the corner: inside a radius-20 arc, outside the radius-24 one. Only a
        // fully round end leaves this pixel on the surface.
        stage.expect("pill-corner-round", 26, 246, Colors.surface)
        // x+10 stays clear of the 26px badge centered at the tile bottom.
        stage.expect("level-fill-25pct", 30, 320 + 58 * 0.75, Colors.primary)
        // Fill must follow the tile's rounded bottom corners.
        stage.expect("level-corner-round", 21, 377, Colors.surface)
        stage.expect("level-empty-85pct", 49, 320 + 58 * 0.15, Colors.surfaceContainerHighest)
      })
    }

    // Keyboard path of the level badge (QtTest keyClick), run after the grab.
    TestCase {
      name: "badge"
      when: true
      function test_badge() {
        wait(1500)
        var badge = null
        for (var i = 0; i < tile.children.length; i++)
          if (tile.children[i].objectName === "badge") badge = tile.children[i]
        win.badgeClicks = 0
        badge.forceActiveFocus()
        keyClick(Qt.Key_Space)
        console.log("BEHAVE badge-focus-and-space-emits-iconClicked "
          + (badge.activeFocus && win.badgeClicks === 1 ? 1 : 0))
        console.log("BEHAVE badge-tooltip-from-accessibleName "
          + (badge.tooltipText === "Test level" && badge.accessibleName === "Test level" ? 1 : 0))
        console.log("BEHAVE badge-hit-box-at-least-48 " + (badge.height >= 48 ? 1 : 0))
        Qt.quit()
      }
    }
  }
}
