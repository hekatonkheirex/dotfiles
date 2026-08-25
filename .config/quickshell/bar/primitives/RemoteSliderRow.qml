// bar/primitives/RemoteSliderRow.qml
// Label + SliderControl backed by a niri_config CLI field, for a bounded
// numeric range. `min`/`max` define the slider's real-value range;
// `unit` is cosmetic display text (e.g. "px", "ms", "%").
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../../config"

RowLayout {
  id: root

  property string cliFile: ""
  property string cliField: ""
  property var extraArgs: []
  property string label: ""
  property real min: 0
  property real max: 100
  property real value: min
  property string unit: ""
  property int decimals: 0
  signal writeFailed(string message)

  Layout.fillWidth: true
  spacing: Config.spacingMedium

  Text {
    text: root.label
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.textBodySize
    Layout.preferredWidth: 120
  }

  SliderControl {
    id: slider
    Layout.fillWidth: true
    value: root.max > root.min ? (root.value - root.min) / (root.max - root.min) : 0
    stepSize: root.max > root.min ? Math.pow(10, -root.decimals) / (root.max - root.min) : 0.01
    accessibleMinimumValue: root.min
    accessibleMaximumValue: root.max
    accessibleUnit: root.unit
    activeColor: Colors.primary
    surfaceContainerHigh: Colors.surfaceContainerHigh
    surfaceContainerHighest: Colors.surfaceContainerHighest
    outline: Colors.styleOutlineStrong
    focusColor: Colors.primary
    motionDuration: Config.motionMedium
    reducedMotion: Config.reducedMotion
    accessibleName: root.label
    onChanged: function(val) {
      root.value = root.min + val * (root.max - root.min)
    }
    onInteractionFinished: root.commit()
  }

  Text {
    text: root.decimals > 0 ? root.value.toFixed(root.decimals) + root.unit : Math.round(root.value) + root.unit
    color: Colors.fgSurface
    font.family: Config.fontFamily
    font.pixelSize: 11
    Layout.preferredWidth: 50
  }

  Process {
    id: readProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseFloat(text.trim())
        if (!isNaN(v)) root.value = v
      }
    }
  }

  Process {
    id: writeProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          root.reload()
          root.writeFailed(text.trim())
        }
      }
    }
  }

  function reload() {
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function commit() {
    var formatted = root.decimals > 0 ? root.value.toFixed(root.decimals) : String(Math.round(root.value))
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, formatted].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  Component.onCompleted: root.reload()
}
