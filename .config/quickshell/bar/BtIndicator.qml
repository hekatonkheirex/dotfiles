import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Colors.primary
  accessibleName: "Bluetooth"
  tooltipText: "Bluetooth"

  property bool btOn: false
  property string btDeviceMac: ""
  property string btDeviceBattery: ""

  Process {
    id: btQuery
    command: ["sh", "-c", "echo $(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')___$(MAC=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2) && [ -n \"$MAC\" ] && echo \"$MAC\" || echo \"\")___$(MAC=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2) && [ -n \"$MAC\" ] && bluetoothctl info \"$MAC\" 2>/dev/null | grep \"Battery Percentage:\" | awk -F '[()]' '{print $2}' || echo \"\")"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var clean = text.trim()
        var parts = clean.split("___")
        root.btOn = parts[0] === "yes"
        root.btDeviceMac = parts.length > 1 ? parts[1] : ""
        root.btDeviceBattery = parts.length > 2 ? parts[2].trim() : ""
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 5000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: btQuery.running = true
  }

  onVisibleChanged: {
    if (visible) btQuery.running = true
  }

  Component.onCompleted: {
    if (root.visible) btQuery.running = true
  }

  iconLabel: {
    if (!root.btOn) return "bluetooth_disabled"
    if (root.btDeviceMac !== "") return "bluetooth_connected"
    return "bluetooth"
  }
  labelText: {
    if (!root.btOn) return "Off"
    if (root.btDeviceMac !== "" && root.btDeviceBattery !== "") return root.btDeviceBattery + "%"
    return "On"
  }
}
