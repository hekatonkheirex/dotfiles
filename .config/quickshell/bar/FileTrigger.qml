import QtQuick
import Quickshell
import Quickshell.Io

// Watches /tmp for a set of trigger files. `triggers` maps file basename to a
// name emitted via triggered(name). One inotifywait process covers all files
// instead of one per file.
Item {
  id: root

  property var triggers: ({})
  signal triggered(string name)

  readonly property var fileNames: Object.keys(triggers)

  function fire(fileName) {
    Quickshell.execDetached(["rm", "-f", "/tmp/" + fileName]);
    root.triggered(root.triggers[fileName]);
  }

  // Main watcher process: runs inotifywait in monitor mode.
  // This process runs persistently and NEVER exits under normal operation,
  // resulting in zero CPU consumption when idle.
  Process {
    id: proc
    command: ["inotifywait", "-m", "-e", "create", "--format", "%f", "/tmp/"]
    running: root.fileNames.length > 0

    stdout: SplitParser {
      onRead: function(line) {
        var trimmed = line.trim();
        if (root.triggers[trimmed] !== undefined) {
          root.fire(trimmed);
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
      if (root.fileNames.length > 0) {
        proc.running = true;
      }
    }
  }

  // Handle the initial state: if any trigger file already exists on startup,
  // fire it and clean it up immediately.
  Component.onCompleted: {
    checkInitialFiles.start();
  }

  Timer {
    id: checkInitialFiles
    interval: 100
    onTriggered: {
      checkProc.running = true;
    }
  }

  Process {
    id: checkProc
    command: ["sh", "-c", "cd /tmp && ls -1 " + root.fileNames.join(" ") + " 2>/dev/null; true"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
          var f = lines[i].trim();
          if (root.triggers[f] !== undefined) {
            root.fire(f);
          }
        }
      }
    }
  }
}
