import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import "../config"

PopupBase {
  id: root

  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingExtraLarge, 450)

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
    // prefer the real battery device (has voltage, capacity)
    for (var i = 0; i < UPower.devices.count; i++) {
      var d = UPower.devices.get(i)
      if (d.ready && d.isLaptopBattery) return d
    }
    // fall back to display device
    if (UPower.displayDevice && UPower.displayDevice.ready)
      return UPower.displayDevice
    return null
  }

  function updateBattery() {
    var dev = root.findBattery()
    if (dev) {
      root.batteryDevice = dev
      // UPowerDevice.percentage is 0-1, convert to 0-100
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
    command: ["sh", "-c", "battery=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' -print -quit 2>/dev/null); if [ -n \"$battery\" ] && [ -r \"$battery/cycle_count\" ]; then cat \"$battery/cycle_count\"; fi"]
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

  onShown: {
    root.updateBattery()
    cycleQuery.running = true
  }

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingMedium

    Text {
      text: "Battery"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeHeadlineSmallSize
      font.weight: Config.typeStrongWeight
      font.letterSpacing: Config.typeHeadlineTracking
      lineHeight: Config.typeHeadlineSmallLineHeight
      lineHeightMode: Text.FixedHeight
    }

    PopupDivider {}

    Row {
      spacing: Config.spacingMedium
      Text {
        text: pct >= 0 ? Math.round(pct) + "%" : "--%"
        color: (pct <= 10 ? Colors.destructive : Colors.fgSurface)
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineLargeSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
        lineHeight: Config.typeHeadlineLargeLineHeight
        lineHeightMode: Text.FixedHeight
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.spacingCompact
        Text {
          text: root.stateLabel
          color: (root.charging ? Colors.primary : Colors.fgSurfaceVariant)
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleSmallSize
          font.weight: Config.typeMediumWeight
          font.letterSpacing: Config.typeTitleTracking
        }
        Text {
          text: batteryDevice && batteryDevice.energyCapacity ? batteryDevice.energyCapacity.toFixed(1) + " Wh" : ""
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyMediumSize
          font.letterSpacing: Config.typeBodyTracking
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
        color: pct < 0 ? "transparent" : (root.charging || pct > 20 ? (Colors.primary) : (Colors.warning))
      }
    }

    Text {
      text: root.timeLabel
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
      font.letterSpacing: Config.typeBodyTracking
      visible: root.timeLabel !== ""
    }

    RowLayout {
      width: parent.width
      visible: batteryDevice !== null
      spacing: 0

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact
        Text {
          text: root.charging ? "Charge Rate" : "Discharge Rate"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyMediumSize
          font.letterSpacing: Config.typeBodyTracking
        }
        Text {
          text: batteryDevice && batteryDevice.changeRate !== undefined ? batteryDevice.changeRate.toFixed(1) + " W" : "-- W"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleSmallSize
          font.weight: Config.typeMediumWeight
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact
        Text {
          text: "Cycle Count"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyMediumSize
          font.letterSpacing: Config.typeBodyTracking
        }
        Text {
          text: root.cycles
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleSmallSize
          font.weight: Config.typeMediumWeight
        }
      }
    }

    Text {
      text: batteryDevice ? batteryDevice.model || batteryDevice.vendor || "" : ""
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
      font.letterSpacing: Config.typeBodyTracking
    }
  }
}
