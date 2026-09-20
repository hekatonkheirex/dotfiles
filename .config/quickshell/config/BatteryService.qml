pragma Singleton
import QtQml
import Quickshell.Services.UPower

QtObject {
  id: root

  readonly property var batteryDevice: {
    for (var i = 0; i < UPower.devices.count; i++) {
      var device = UPower.devices.get(i)
      if (device.ready && device.isLaptopBattery) return device
    }
    if (UPower.displayDevice && UPower.displayDevice.ready) return UPower.displayDevice
    return null
  }

  readonly property real pct: batteryDevice ? batteryDevice.percentage * 100 : -1
}
