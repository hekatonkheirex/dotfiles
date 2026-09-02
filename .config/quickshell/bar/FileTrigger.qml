import QtQuick
import Quickshell
import Quickshell.Io

// Watches the user's Quickshell runtime directory for trigger files.
// `triggers` maps file basename to a name emitted via triggered(name). One
// inotifywait process covers all files instead of one per file.
Item {
  id: root

  property var triggers: ({})
  signal triggered(string name)

  readonly property var fileNames: Object.keys(triggers)
  readonly property string runtimeDirectory: {
    var xdgRuntime = Quickshell.env("XDG_RUNTIME_DIR")
    return xdgRuntime
      ? xdgRuntime + "/quickshell"
      : Quickshell.env("HOME") + "/.cache/quickshell/runtime"
  }

  function fire(fileName) {
    Quickshell.execDetached(["rm", "-f", root.runtimeDirectory + "/" + fileName]);
    root.triggered(root.triggers[fileName]);
  }

  // Main watcher process: runs inotifywait in monitor mode.
  // This process runs persistently and NEVER exits under normal operation,
  // resulting in zero CPU consumption when idle.
  Process {
    id: proc
    command: [
      "sh", "-c",
      "mkdir -p -- \"$1\" && (chmod 700 -- \"$1\" 2>/dev/null || [ \"$(stat -c %a -- \"$1\" 2>/dev/null)\" = 700 ]) && exec inotifywait -m -e create --format %f \"$1\"",
      "sh", root.runtimeDirectory
    ]
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
    command: [
      "sh", "-c",
      "runtime_dir=\"$1\"; shift; for name do if [ -e \"$runtime_dir/$name\" ]; then printf '%s\\n' \"$name\"; fi; done",
      "sh", root.runtimeDirectory
    ].concat(root.fileNames)
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
