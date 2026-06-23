import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  property bool active: false
  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

  readonly property var batteryDevice: {
    for (var i = 0; i < UPower.devices.count; i++) {
      var d = UPower.devices.get(i)
      if (d.ready && d.isLaptopBattery) return d
    }
    if (UPower.displayDevice && UPower.displayDevice.ready)
      return UPower.displayDevice
    return null
  }

  readonly property real pct: batteryDevice ? batteryDevice.percentage * 100 : -1

  readonly property string iconLabel: {
    if (!batteryDevice) return "battery_unknown"
    var ch = batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge
    var plugged = ch || batteryDevice.state === UPowerDeviceState.FullyCharged
    if (ch) return "battery_charging_full"
    if (plugged && pct >= 99) return "battery_full"
    if (pct <= 10) return "battery_alert"
    if (pct <= 20) return "battery_1_bar"
    if (pct <= 40) return "battery_2_bar"
    if (pct <= 60) return "battery_3_bar"
    if (pct <= 80) return "battery_4_bar"
    if (pct <= 95) return "battery_5_bar"
    return "battery_full"
  }

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: root.horizontal ? height / 2 : width / 2
    clip: true
    color: {
      if (root.active) return colors_ ? colors_.primary : "#D0BCFF"
      if (mouseArea.containsMouse) return colors_ ? colors_.surfaceContainerHighest : "#36343B"
      return colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    }
    border.color: {
      if (root.active) return "transparent"
      return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
    }
    font.family: config ? config.iconFont : "Material Symbols Outlined"
    font.pixelSize: config ? config.iconSize : 22
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4
    text: root.pct >= 0 ? Math.round(root.pct) + "%" : ""
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
    }
    font.family: config ? config.fontFamily : "Roboto"
    font.pixelSize: config ? (config.fontPixelSize - 2) : 8
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
