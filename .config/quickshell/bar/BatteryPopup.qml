import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Services.UPower
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  visible: false
  implicitHeight: Math.min(contentColumn.implicitHeight + 24, 450)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))
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
      entryAnimation.start()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

    Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      config: root.config
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true
      border.width: 1
      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: 200
          easing.type: Easing.OutCubic
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
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 8) : 18
          font.weight: Font.Bold
        }

        Row {
          spacing: 12
          Text {
            text: pct >= 0 ? Math.round(pct) + "%" : "--%"
            color: colors_ ? (pct <= 10 ? colors_.error : colors_.fgSurface) : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 16) : 26
            font.weight: Font.Bold
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
              text: root.stateLabel
              color: colors_ ? (root.charging ? colors_.primary : colors_.fgSurfaceVariant) : "#CAC4D0"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 2) : 12
              font.weight: Font.Medium
            }
            Text {
              text: batteryDevice && batteryDevice.energyCapacity ? batteryDevice.energyCapacity.toFixed(1) + " Wh" : ""
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 1) : 11
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 10
          radius: 5
          color: colors_ ? colors_.surfaceContainerHighest : "#36343B"
          Rectangle {
            anchors {
              left: parent.left; top: parent.top; bottom: parent.bottom
              leftMargin: 2; topMargin: 2; bottomMargin: 2
            }
            width: (parent.width - 4) * Math.max(0, Math.min(1, root.pct / 100))
            radius: 3
            color: pct < 0 ? "transparent" : (root.charging || pct > 20 ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.error : "#F2B8B5"))
          }
        }

        Text {
          text: root.timeLabel
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 1) : 11
          visible: root.timeLabel !== ""
        }

        RowLayout {
          width: parent.width
          visible: batteryDevice !== null
          spacing: 0

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
              text: root.charging ? "Charge Rate" : "Discharge Rate"
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 1) : 11
            }
            Text {
              text: batteryDevice && batteryDevice.changeRate !== undefined ? batteryDevice.changeRate.toFixed(1) + " W" : "-- W"
              color: colors_ ? colors_.fgSurface : "#FFFFFF"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 2) : 12
              font.weight: Font.Medium
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
              text: "Cycle Count"
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 1) : 11
            }
            Text {
              text: root.cycles
              color: colors_ ? colors_.fgSurface : "#FFFFFF"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 2) : 12
              font.weight: Font.Medium
            }
          }
        }

        Text {
          text: batteryDevice ? batteryDevice.model || batteryDevice.vendor || "" : ""
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 1) : 11
        }
      }
    }
  }
}
