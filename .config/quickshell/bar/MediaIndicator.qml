import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Config.nothingDesign ? Colors.fgSurface : Colors.primary
  accessibleName: "Media"
  tooltipText: root.mprisTitle ? (root.mprisTitle + (root.mprisArtist ? " - " + root.mprisArtist : "")) : "No media playing"

  property string mprisStatus: "NoPlayer"
  property string mprisTitle: ""
  property string mprisArtist: ""

  Process {
    id: mprisProcess
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_monitor.py"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var info = JSON.parse(data.trim());
          root.mprisStatus = info.status;
          root.mprisTitle = info.title;
          root.mprisArtist = info.artist;
        } catch (e) { print("MediaIndicator parse error:", e) }
      }
    }
    onRunningChanged: {
      if (!running && root.visible) mprisProcessRetry.start()
    }
  }

  Timer {
    id: mprisProcessRetry
    interval: 3000
    onTriggered: {
      if (root.visible) mprisProcess.running = true
    }
  }

  iconLabel: root.mprisStatus === "Playing" ? "pause" : (root.mprisStatus === "Paused" ? "play_arrow" : "music_note")

  onWheel: function(wheel) {
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", wheel.angleDelta.y > 0 ? "prev" : "next"])
  }
}
