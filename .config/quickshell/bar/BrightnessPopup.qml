import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

PopupBase {
  id: root

  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 400)

  property real pct: 0

  function setBrightness(val) {
    root.pct = Math.max(0, Math.min(100, val))
    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pct) + "%"])
  }

  Process {
    id: getProc
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseFloat(text.trim())
        if (!isNaN(val)) root.pct = val
      }
    }
  }

  function pollBrightness() { getProc.running = true }

  Process {
    id: brightnessWatcher
    command: ["sh", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) { root.pollBrightness() }
    }
    onRunningChanged: {
      if (!running && root.visible) brightnessWatcherRetry.start()
    }
  }

  Timer {
    id: brightnessWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.visible) brightnessWatcher.running = true
    }
  }

  onShown: root.pollBrightness()

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingLarge

    Text {
      text: "Brightness"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeHeadlineSmallSize
      font.weight: Config.typeStrongWeight
      font.letterSpacing: Config.typeHeadlineTracking
      lineHeight: Config.typeHeadlineSmallLineHeight
      lineHeightMode: Text.FixedHeight
    }

    PopupDivider {}

    Text {
      text: Math.round(root.pct) + "%"
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.letterSpacing: Config.typeTitleTracking
      lineHeight: Config.typeTitleMediumLineHeight
      lineHeightMode: Text.FixedHeight
    }

    SliderControl {
      value: root.pct / 100
      activeColor: Colors.brightness
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
      outline: Colors.styleOutlineStrong
      focusColor: Colors.brightness
      motionDuration: Config.motionMedium
      reducedMotion: Config.reducedMotion
      accessibleName: "Brightness"
      accessibleDescription: "Adjust display brightness"
      onChanged: function(val) { root.setBrightness(val * 100) }
    }
  }
}
