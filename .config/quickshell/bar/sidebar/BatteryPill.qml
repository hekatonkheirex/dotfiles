import QtQuick
import Quickshell.Services.UPower
import "../../config"
import "../primitives"

Rectangle {
  id: root

  readonly property bool present: BatteryService.pct >= 0
  // Truthiness check: batteryDevice is null when absent, tolerate undefined too.
  readonly property bool charging: !!BatteryService.batteryDevice
    && BatteryService.batteryDevice.state === UPowerDeviceState.Charging

  visible: root.present
  implicitHeight: 52
  radius: height / 2
  color: Colors.tertiary

  Row {
    anchors.centerIn: parent
    spacing: Config.spacingSmall

    IconGlyph {
      anchors.verticalCenter: parent.verticalCenter
      iconLabel: root.charging ? "bolt" : "battery_full"
      iconColor: Colors.fgTertiary
      iconSize: 20
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Math.round(BatteryService.pct) + "%"
      color: Colors.fgTertiary
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.weight: Font.Medium
    }
  }
}
