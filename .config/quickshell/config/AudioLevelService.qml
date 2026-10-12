pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "AudioLevel.js" as AudioLevel

// Whether there is sound, for the bar's signal wave. cava runs only while a
// player reports Playing and the bar asks for it. `active` turns on with the
// first sound and off after a short stretch of silence, so quiet passages
// between notes do not make the wave stutter.
QtObject {
  id: root

  // Set by the bar while a wave is on screen and motion is allowed.
  property bool wanted: false
  property bool active: false

  readonly property bool running: root.wanted && MediaService.status === "Playing"
  property bool processEnabled: true

  onRunningChanged: {
    if (!root.running) {
      root.active = false
      hush.stop()
      retry.stop()
    }
  }

  property var cava: Process {
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/config/cava.ini"]
    running: root.running && root.processEnabled
    stdout: SplitParser {
      onRead: function(data) {
        if (!AudioLevel.hasSound(AudioLevel.parse(data))) return
        root.active = true
        hush.restart()
      }
    }
    onRunningChanged: {
      if (!running && root.running) retry.start()
    }
  }

  property var hush: Timer {
    interval: 700
    onTriggered: root.active = false
  }

  property var retry: Timer {
    interval: 2000
    onTriggered: {
      if (!root.running) return
      root.processEnabled = false
      root.processEnabled = true
    }
  }
}
