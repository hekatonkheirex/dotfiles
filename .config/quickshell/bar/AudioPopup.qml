import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

PopupBase {
  id: root

  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 400)

  property real volume: 0.5
  property bool muted: false
  property real micVolume: 0.5
  property bool micMuted: false

  function setVolume(val) {
    root.volume = Math.max(0, Math.min(1, val))
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.volume)])
  }

  function toggleMute() {
    root.muted = !root.muted
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"])
  }

  function setMicVolume(val) {
    root.micVolume = Math.max(0, Math.min(1, val))
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(root.micVolume)])
  }

  function toggleMicMute() {
    root.micMuted = !root.micMuted
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.micMuted ? "1" : "0"])
  }

  Process {
    id: audioQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.volume = parseFloat(m[1])
        root.muted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  Process {
    id: micQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.micVolume = parseFloat(m[1])
        root.micMuted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  function pollAudio() { audioQuery.running = true; micQuery.running = true }

  Process {
    id: audioWatcher
    command: ["pactl", "subscribe"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        if (data.indexOf("sink") >= 0 || data.indexOf("source") >= 0) root.pollAudio()
      }
    }
    onRunningChanged: {
      if (!running && root.visible) audioWatcherRetry.start()
    }
  }

  Timer {
    id: audioWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.visible) audioWatcher.running = true
    }
  }

  onShown: root.pollAudio()

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingLarge

    Item {
      width: parent.width
      height: 32

      Text {
        text: "Volume"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
        lineHeight: Config.typeHeadlineSmallLineHeight
        lineHeightMode: Text.FixedHeight
        anchors.verticalCenter: parent.verticalCenter
      }

      SwitchControl {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: !root.muted
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Volume enabled"
        onToggled: root.toggleMute()
      }
    }

    PopupDivider {}

    Text {
      text: muted ? "Muted" : Math.round(volume * 100) + "%"
      color: muted ? (Colors.error) : (Colors.fgSurfaceVariant)
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.letterSpacing: Config.typeTitleTracking
      lineHeight: Config.typeTitleMediumLineHeight
      lineHeightMode: Text.FixedHeight
    }

      SliderControl {
      value: root.volume
      muted: root.muted
      activeColor: Colors.primary
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        focusColor: Colors.primary
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Volume"
        accessibleDescription: "Adjust output volume"
        onChanged: function(val) { root.setVolume(val) }
    }

    PopupDivider {}

    Item {
      width: parent.width
      height: 32

      Text {
        text: "Microphone"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
        lineHeight: Config.typeHeadlineSmallLineHeight
        lineHeightMode: Text.FixedHeight
        anchors.verticalCenter: parent.verticalCenter
      }

      SwitchControl {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: !root.micMuted
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Microphone enabled"
        onToggled: root.toggleMicMute()
      }
    }

    Text {
      text: micMuted ? "Muted" : Math.round(micVolume * 100) + "%"
      color: micMuted ? (Colors.error) : (Colors.fgSurfaceVariant)
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.letterSpacing: Config.typeTitleTracking
      lineHeight: Config.typeTitleMediumLineHeight
      lineHeightMode: Text.FixedHeight
    }

      SliderControl {
      value: root.micVolume
      muted: root.micMuted
      activeColor: Colors.primary
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        focusColor: Colors.primary
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Microphone volume"
        accessibleDescription: "Adjust microphone volume"
        onChanged: function(val) { root.setMicVolume(val) }
    }
  }
}
