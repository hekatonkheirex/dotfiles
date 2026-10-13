// Copied to the root of a config copy by scripts/sidebar-render.sh.
// Renders SidebarContent on the panel surface and saves $GOLDEN_OUT.
import QtQuick
import Quickshell
import "config"
import "bar/sidebar"

ShellRoot {
  FloatingWindow {
    implicitWidth: 320
    implicitHeight: 640
    color: Colors.surface

    Item {
      id: stage
      width: 320
      height: 640

      Rectangle { anchors.fill: parent; color: Colors.surface }
      SidebarContent {
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
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
