import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "SidebarStats.js" as Stats

Card {
  id: root
  property bool active: false
  property real uptimeSeconds: -1
  property real loadAverage: -1
  property var memoryUsage: null
  readonly property bool polling: refreshTimer.running
  implicitHeight: rows.implicitHeight + Config.spacingMedium * 2

  function refresh() {
    if (!root.active) return
    uptimeFile.reload()
    memoryFile.reload()
    loadFile.reload()
  }

  FileView {
    id: uptimeFile
    path: root.active ? "/proc/uptime" : ""
    onLoaded: {
      var value = Stats.firstNumber(text())
      root.uptimeSeconds = value === null ? -1 : value
    }
    onLoadFailed: root.uptimeSeconds = -1
  }
  FileView {
    id: memoryFile
    path: root.active ? "/proc/meminfo" : ""
    onLoaded: root.memoryUsage = Stats.memory(text())
    onLoadFailed: root.memoryUsage = null
  }
  FileView {
    id: loadFile
    path: root.active ? "/proc/loadavg" : ""
    onLoaded: {
      var value = Stats.firstNumber(text())
      root.loadAverage = value === null ? -1 : value
    }
    onLoadFailed: root.loadAverage = -1
  }
  Timer {
    id: refreshTimer
    interval: 5000
    repeat: true
    running: root.active
    onTriggered: root.refresh()
  }

  component StatRow: RowLayout {
    property string label
    property string value
    Layout.fillWidth: true
    Text {
      Layout.fillWidth: true
      text: parent.label
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelLargeSize
    }
    Text {
      text: parent.value
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelLargeSize
      Accessible.role: Accessible.StaticText
      Accessible.name: parent.label + ": " + parent.value
    }
  }

  ColumnLayout {
    id: rows
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Config.spacingMedium }
    spacing: Config.spacingSmall
    StatRow { label: "Uptime"; value: Stats.uptimeLabel(root.uptimeSeconds) }
    StatRow { label: "Memory"; value: Stats.memoryLabel(root.memoryUsage) }
    StatRow { label: "CPU load (1m)"; value: root.loadAverage < 0 ? "Unavailable" : root.loadAverage.toFixed(2) }
  }
}
