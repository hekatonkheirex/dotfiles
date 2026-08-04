import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Colors.primary
  accessibleName: "Wi-Fi"
  tooltipText: "Wi-Fi"

  property bool wifiOn: false
  property int wifiSignal: -1

  iconLabel: "wifi"

  Process {
    id: wifiQuery
    command: ["sh", "-c", "echo $(nmcli radio wifi)___$(nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var clean = text.trim()
        var parts = clean.split("___")
        root.wifiOn = parts[0] === "enabled"
        if (parts.length > 1 && parts[1]) {
          var sig = parseInt(parts[1])
          root.wifiSignal = isNaN(sig) ? -1 : sig
        } else {
          root.wifiSignal = -1
        }
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 10000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: wifiQuery.running = true
  }

  iconOpacity: {
    if (!root.wifiOn) return 0.25
    if (root.wifiSignal < 0) return 0.4
    if (root.wifiSignal <= 25) return 0.55
    if (root.wifiSignal <= 50) return 0.7
    if (root.wifiSignal <= 75) return 0.85
    return 1.0
  }
  labelText: root.wifiOn && root.wifiSignal >= 0 ? root.wifiSignal + "%" : "--%"
  labelOpacity: {
    if (!root.wifiOn) return 0.35
    if (root.wifiSignal < 0) return 0.5
    return 1.0
  }
}
