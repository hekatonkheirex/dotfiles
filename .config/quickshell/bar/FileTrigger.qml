import QtQuick
import Quickshell.Io

Item {
  id: root

  property string triggerFile: ""
  signal triggered()

  Process {
    id: proc
    command: ["sh", "-c",
      "while true; do inotifywait -e create /tmp/ 2>/dev/null | grep -q '" + root.triggerFile.split("/").pop() + "' && { rm -f " + root.triggerFile + "; break; }; done"
    ]
    running: root.triggerFile.length > 0
    onRunningChanged: {
      if (!running && root.triggerFile.length > 0) {
        root.triggered()
        restartTimer.start()
      }
    }
  }

  Timer {
    id: restartTimer
    interval: 1
    onTriggered: proc.running = true
  }
}
