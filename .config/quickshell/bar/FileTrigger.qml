import QtQuick
import Quickshell.Io

Item {
  id: root

  property string triggerFile: ""
  signal triggered()

  Process {
    id: proc
    command: ["sh", "-c",
      "if [ -f " + root.triggerFile + " ]; then rm -f " + root.triggerFile + "; else inotifywait -e create /tmp/ 2>/dev/null | grep -q '" + root.triggerFile.split("/").pop() + "' && rm -f " + root.triggerFile + "; fi"
    ]
    running: root.triggerFile.length > 0
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        root.triggered()
      }
      restartTimer.start()
    }
  }

  Timer {
    id: restartTimer
    interval: 1
    onTriggered: proc.running = true
  }
}
