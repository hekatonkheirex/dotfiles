import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string triggerFile: ""
  signal triggered()

  property string fileName: triggerFile.split("/").pop()

  // Main watcher process: runs inotifywait in monitor mode.
  // This process runs persistently and NEVER exits under normal operation,
  // resulting in zero CPU consumption when idle.
  Process {
    id: proc
    command: ["inotifywait", "-m", "-e", "create", "--format", "%f", "/tmp/"]
    running: root.triggerFile.length > 0

    stdout: SplitParser {
      onRead: function(line) {
        var trimmed = line.trim();
        if (trimmed === root.fileName) {
          Quickshell.execDetached(["rm", "-f", root.triggerFile]);
          root.triggered();
        }
      }
    }

    // In case the watcher exits (e.g. system suspend or limit updates),
    // restart it after a safe 5-second delay to prevent any CPU busy loop.
    onExited: (exitCode, exitStatus) => {
      restartTimer.start()
    }
  }

  Timer {
    id: restartTimer
    interval: 5000
    onTriggered: {
      if (root.triggerFile.length > 0) {
        proc.running = true;
      }
    }
  }

  // Handle the initial state: if the file already exists on startup,
  // trigger the action and clean up the file immediately.
  Component.onCompleted: {
    checkInitialFile.start();
  }

  Timer {
    id: checkInitialFile
    interval: 100
    onTriggered: {
      checkProc.running = true;
    }
  }

  Process {
    id: checkProc
    command: ["sh", "-c", "if [ -f " + root.triggerFile + " ]; then rm -f " + root.triggerFile + "; exit 0; else exit 1; fi"]
    running: false
    onExited: (exitCode) => {
      if (exitCode === 0) {
        root.triggered();
      }
    }
  }
}
