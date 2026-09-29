import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  accessibleName: "Battery"

  readonly property var batteryDevice: BatteryService.batteryDevice
  readonly property real pct: BatteryService.pct
  readonly property bool charging: batteryDevice
    && (batteryDevice.state === UPowerDeviceState.Charging
      || batteryDevice.state === UPowerDeviceState.PendingCharge)
  readonly property bool discharging: batteryDevice && !charging
    && batteryDevice.state !== UPowerDeviceState.FullyCharged
  readonly property bool lowCharge: Config.ghostTheme && discharging && pct >= 0 && pct <= 20
  iconColor: Config.ghostTheme && discharging && pct >= 0 && pct <= 10
    ? Colors.destructive
    : (lowCharge ? Colors.warning
      : (Config.ghostTheme && charging ? Colors.success
        : (Config.liquidGlassTheme ? Colors.barForeground
          : (Config.ghostTheme && !root.active ? Colors.fgSurfaceVariant : root.accentColor))))
  labelColor: iconColor

  iconLabel: {
    if (!batteryDevice) return "battery_unknown"
    var ch = batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge
    var plugged = ch || batteryDevice.state === UPowerDeviceState.FullyCharged
    if (ch) return "battery_charging_full"
    if (plugged && pct >= 99) return "battery_full"
    if (pct <= 20) return "battery_1_bar"
    if (pct <= 60) return "battery_3_bar"
    return "battery_6_bar"
  }

  labelText: root.pct >= 0 ? Math.round(root.pct) + "%" : ""
}
