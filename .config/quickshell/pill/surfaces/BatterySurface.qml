import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import "../components"
import "../config"

Item {
  id: root

  implicitHeight: contentColumn.implicitHeight + 24

  property var batteryDevice: null
  property real pct: -1
  property var state: null
  property bool charging: false
  property string stateLabel: "No battery"
  property string timeLabel: ""
  property string cycles: "--"

  function formatTime(seconds) {
    if (!seconds || seconds <= 0) return ""
    var h = Math.floor(seconds / 3600)
    var m = Math.floor((seconds % 3600) / 60)
    if (h > 0) return h + "h " + m + "m"
    return m + "m"
  }

  function findBattery() {
    for (var i = 0; i < UPower.devices.count; i++) {
      var d = UPower.devices.get(i)
      if (d.ready && d.isLaptopBattery) return d
    }
    if (UPower.displayDevice && UPower.displayDevice.ready)
      return UPower.displayDevice
    return null
  }

  function updateBattery() {
    var dev = root.findBattery()
    if (dev) {
      root.batteryDevice = dev
      root.pct = dev.percentage * 100
      root.state = dev.state
      var ch = dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge
      root.charging = ch
      if (ch) root.stateLabel = "Charging"
      else if (dev.state === UPowerDeviceState.FullyCharged) root.stateLabel = "Fully charged"
      else if (dev.state === UPowerDeviceState.Discharging) root.stateLabel = "Discharging"
      else if (dev.state === UPowerDeviceState.PendingDischarge) root.stateLabel = "Pending discharge"
      else if (dev.state === UPowerDeviceState.PendingCharge) root.stateLabel = "Pending charge"
      else root.stateLabel = "Unknown"
      if (ch && dev.timeToFull > 0) root.timeLabel = root.formatTime(dev.timeToFull) + " until full"
      else if (!ch && dev.state === UPowerDeviceState.Discharging && dev.timeToEmpty > 0) root.timeLabel = root.formatTime(dev.timeToEmpty) + " remaining"
      else root.timeLabel = ""
    }
  }

  Process {
    id: cycleQuery
    command: ["cat", "/sys/class/power_supply/BAT0/cycle_count"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var c = text.trim()
        if (c.length > 0 && !isNaN(c)) {
          root.cycles = c
        } else {
          root.cycles = "--"
        }
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      root.updateBattery()
      cycleQuery.running = true
    }
  }

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: 12
    }
    spacing: 12

    Text {
      text: "Battery"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: (Config.fontPixelSize + 8)
      font.weight: Font.Bold
    }

    PopupDivider {}

    Row {
      spacing: 12
      Text {
        text: root.pct >= 0 ? Math.round(root.pct) + "%" : "--%"
        color: (root.pct <= 10 ? Colors.destructive : Colors.fgSurface)
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize + 16)
        font.weight: Font.Bold
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
          text: root.stateLabel
          color: (root.charging ? Colors.primary : Colors.fgSurfaceVariant)
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 2)
          font.weight: Font.Medium
        }
        Text {
          text: root.batteryDevice && root.batteryDevice.energyCapacity ? root.batteryDevice.energyCapacity.toFixed(1) + " Wh" : ""
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 1)
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 10
      radius: 5
      color: Colors.surfaceContainerHighest
      Rectangle {
        anchors {
          left: parent.left; top: parent.top; bottom: parent.bottom
          leftMargin: 2; topMargin: 2; bottomMargin: 2
        }
        width: (parent.width - 4) * Math.max(0, Math.min(1, root.pct / 100))
        radius: 3
        color: root.pct < 0 ? "transparent" : (root.charging || root.pct > 20 ? (Colors.primary) : (Colors.warning))
      }
    }

    Text {
      text: root.timeLabel
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: (Config.fontPixelSize + 1)
      visible: root.timeLabel !== ""
    }

    RowLayout {
      width: parent.width
      visible: root.batteryDevice !== null
      spacing: 0

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
          text: root.charging ? "Charge Rate" : "Discharge Rate"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 1)
        }
        Text {
          text: root.batteryDevice && root.batteryDevice.changeRate !== undefined ? root.batteryDevice.changeRate.toFixed(1) + " W" : "-- W"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 2)
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
          text: "Cycle Count"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 1)
        }
        Text {
          text: root.cycles
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 2)
          font.weight: Font.Medium
        }
      }
    }

    Text {
      text: root.batteryDevice ? root.batteryDevice.model || root.batteryDevice.vendor || "" : ""
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: (Config.fontPixelSize + 1)
    }
  }
}
