// Copied to the root of a config copy by scripts/dock-render.sh.
// Renders DockContent on the panel surface and saves $GOLDEN_OUT.
import QtQuick
import Quickshell
import "config"
import "bar/dock"

ShellRoot {
  FloatingWindow {
    implicitWidth: 214
    implicitHeight: 81
    color: Colors.surface

    // Fixed stage: niri tiles FloatingWindow to arbitrary sizes.
    Item {
      id: stage
      width: 214
      height: 81

      Rectangle { anchors.fill: parent; color: Colors.surface }
      DockContent {
        anchors.centerIn: parent
        items: [
          { appId: "brave-origin", pinned: true,  count: 0, windowIds: [],  focused: false, urgent: false },
          { appId: "kitty",        pinned: true,  count: 1, windowIds: [3], focused: false, urgent: false },
          { appId: "zed",          pinned: false, count: 1, windowIds: [7], focused: true,  urgent: false }
        ]
      }
    }

    Timer {
      interval: 2500
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        Qt.quit()
      })
    }
  }
}
