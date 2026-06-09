import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

  property var batteryDevice: null
  property real pct: -1
  property string iconLabel: "battery_unknown"

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
    if (!dev) return
    root.batteryDevice = dev
    root.pct = dev.percentage * 100
    var ch = dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge
    var plugged = ch || dev.state === UPowerDeviceState.FullyCharged
    if (ch) root.iconLabel = "battery_charging_full"
    else if (plugged && root.pct >= 99) root.iconLabel = "battery_full"
    else if (root.pct <= 10) root.iconLabel = "battery_alert"
    else if (root.pct <= 20) root.iconLabel = "battery_1_bar"
    else if (root.pct <= 40) root.iconLabel = "battery_2_bar"
    else if (root.pct <= 60) root.iconLabel = "battery_3_bar"
    else if (root.pct <= 80) root.iconLabel = "battery_4_bar"
    else if (root.pct <= 95) root.iconLabel = "battery_5_bar"
    else root.iconLabel = "battery_full"
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.updateBattery()
  }

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: 6
      rightMargin: 6
    }
    radius: config ? config.borderRadius : 14
    clip: true
    color: colors_ ? (mouseArea.containsMouse ? colors_.surfaceContainerHighest : colors_.surfaceContainerHigh) : "#2B2930"
    border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: colors_ ? colors_.primary : "#D0BCFF"
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
    color: colors_ ? colors_.primary : "#D0BCFF"
    font.family: config ? config.fontFamily : "Google Sans Flex"
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
