// Forked from bar/BatteryIndicator.qml (identical apart from import paths,
// with the "primitives" import dropped since StatusIndicator is now a
// same-directory sibling). Cross-root import is impossible under 'qs -p';
// see docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in
// sync until bar/ is retired.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../config"

StatusIndicator {
  id: root

  accentColor: Colors.primary
  accessibleName: "Battery"

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

  iconLabel: {
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

  labelText: root.pct >= 0 ? Math.round(root.pct) + "%" : ""
}
