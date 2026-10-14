// Copied to the root of a config copy by scripts/tag-strip-render.sh.
// Renders three TagStripBlocks rows over the palette surface (A plain, B with
// the empty workspace 3 hovered, C with the occupied workspace 1 hovered) and
// saves $GOLDEN_OUT. Logs the accent colors for the pixel stage.
import QtQuick
import Quickshell
import "config"
import "bar"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 450
    implicitHeight: 24
    color: Colors.surface

    readonly property var model: [
      { idx: 1, isFocused: false, isOccupied: true },
      { idx: 2, isFocused: true, isOccupied: true },
      { idx: 3, isFocused: false, isOccupied: false },
      { idx: 4, isFocused: false, isOccupied: true },
      { idx: 5, isFocused: false, isOccupied: false },
      { idx: 6, isFocused: true, isOccupied: false }
    ]

    Item {
      id: stage
      // Fixed size: the compositor may tile the window larger than 450x24.
      width: 450
      height: 24
      Rectangle { anchors.fill: parent; color: Colors.surface }
      TagStripBlocks { width: 450; height: 8; workspaces: win.model }
      TagStripBlocks { y: 8; width: 450; height: 8; workspaces: win.model; forceHoverIdx: 3 }
      TagStripBlocks { y: 16; width: 450; height: 8; workspaces: win.model; forceHoverIdx: 1 }
    }

    Component.onCompleted: Config.reducedMotion = true

    Timer {
      interval: 2000
      running: true
      onTriggered: stage.grabToImage(function(r) {
        for (var n = 1; n <= 6; n++) console.log("COLOR x" + n + " " + Colors.elenaAccent(n))
        console.log("COLOR surface " + Colors.surface)
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        Qt.quit()
      })
    }
  }
}
