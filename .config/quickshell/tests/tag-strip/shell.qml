// Copied to the root of a config copy by scripts/tag-strip-render.sh.
// Renders TagStripBlocks over the palette surface and saves $GOLDEN_OUT.
import QtQuick
import Quickshell
import "config"
import "bar"

ShellRoot {
  FloatingWindow {
    implicitWidth: 450
    implicitHeight: 8
    color: Colors.surface

    Item {
      id: stage
      // Fixed size: the compositor may tile the window larger than 450x8.
      width: 450
      height: 8
      Rectangle { anchors.fill: parent; color: Colors.surface }
      TagStripBlocks {
        anchors.fill: parent
        workspaces: [
          { idx: 1, isFocused: false, isOccupied: true },
          { idx: 2, isFocused: true, isOccupied: true },
          { idx: 3, isFocused: false, isOccupied: false },
          { idx: 4, isFocused: false, isOccupied: true },
          { idx: 5, isFocused: false, isOccupied: false },
          { idx: 6, isFocused: true, isOccupied: false }
        ]
      }
    }

    Timer {
      interval: 2000
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        Qt.quit()
      })
    }
  }
}
