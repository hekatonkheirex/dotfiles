import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

PopupBase {
  id: root

  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 400)

  property real pct: 0

  function setBrightness(val) {
    root.pct = Math.max(0, Math.min(100, val))
    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pct) + "%"])
  }

  Process {
    id: getProc
    command: ["brightnessctl", "-m"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        // format: device,class,current_raw,percentage%,max_raw
        var parts = text.trim().split(",")
        if (parts.length < 5) return
        var pctStr = parts[3].replace("%", "")
        var val = parseFloat(pctStr)
        if (!isNaN(val)) root.pct = val
      }
    }
  }

  function pollBrightness() { getProc.running = true }

  Timer {
    interval: 300
    running: root.visible
    repeat: true
    onTriggered: root.pollBrightness()
  }

  onShown: root.pollBrightness()

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: 16

    Text {
      text: "Brightness"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: (Config.fontPixelSize + 8)
      font.weight: Font.Bold
    }

    PopupDivider {}

    Text {
      text: Math.round(root.pct) + "%"
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: (Config.fontPixelSize + 4)
    }

    SliderControl {
      value: root.pct / 100
      activeColor: Colors.brightness
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
      outline: Colors.outline
      focusColor: Colors.brightness
      motionDuration: Config.motionMedium
      reducedMotion: Config.reducedMotion
      accessibleName: "Brightness"
      accessibleDescription: "Adjust display brightness"
      onChanged: function(val) { root.setBrightness(val * 100) }
    }
  }
}
