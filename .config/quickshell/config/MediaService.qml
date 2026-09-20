pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string status: "NoPlayer"
  property string title: ""
  property string artist: ""
  property string album: ""
  property string artUrl: ""
  property int lengthSec: 0
  property string lengthStr: "0:00"
  property bool indicatorActive: false
  property bool popupActive: false
  property bool monitorEnabled: true

  readonly property bool active: indicatorActive || popupActive

  onActiveChanged: {
    if (!root.active) monitorRetry.stop()
  }

  property var monitorProcess: Process {
    command: [
      "python3", "-u",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_monitor.py"
    ]
    running: root.active && root.monitorEnabled
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var info = JSON.parse(data.trim())
          root.status = info.status
          root.title = info.title
          root.artist = info.artist
          root.album = info.album
          root.artUrl = info.artUrl
          root.lengthSec = info.length_sec
          root.lengthStr = info.length_str
        } catch (error) {
          print("MediaService parse error:", error)
        }
      }
    }
    onRunningChanged: {
      if (!running && root.active && root.monitorEnabled) monitorRetry.start()
    }
  }

  property var monitorRetry: Timer {
    interval: 3000
    onTriggered: {
      if (!root.active) return
      root.monitorEnabled = false
      root.monitorEnabled = true
    }
  }
}
