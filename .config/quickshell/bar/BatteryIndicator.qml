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
    if (!batteryDevice) return "battery_horiz_000"
    var ch = batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge
    var plugged = ch || batteryDevice.state === UPowerDeviceState.FullyCharged
    if (ch) return "battery_horiz_075"
    if (plugged && pct >= 99) return "battery_horiz_075"
    if (pct <= 20) return "battery_horiz_000"
    if (pct <= 60) return "battery_horiz_050"
    return "battery_horiz_075"
  }

  labelText: root.pct >= 0 ? Math.round(root.pct) + "%" : ""
}
