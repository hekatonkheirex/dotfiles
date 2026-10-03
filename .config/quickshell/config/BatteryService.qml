pragma Singleton
import QtQml
import Quickshell.Io
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

  // Charge-stop threshold (percent) from the kernel, set by TLP or similar.
  // -1 when the machine exposes none.
  property int chargeLimit: -1
  readonly property bool held: batteryDevice
    && batteryDevice.state === UPowerDeviceState.PendingCharge
  // pending-charge means plugged in but held by a charge threshold.
  readonly property string heldLabel: chargeLimit > 0
    ? "Holding at " + chargeLimit + "% limit" : "Plugged in, holding charge"

  function refreshChargeLimit() {
    if (!limitQuery.running) limitQuery.running = true
  }

  // Re-read when a hold starts: the threshold can change without a restart.
  onHeldChanged: if (held) refreshChargeLimit()
  Component.onCompleted: refreshChargeLimit()

  property Process limitQuery: Process {
    command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null | head -n 1"]
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseInt(text.trim())
        root.chargeLimit = (v > 0 && v < 100) ? v : -1
      }
    }
  }
}
