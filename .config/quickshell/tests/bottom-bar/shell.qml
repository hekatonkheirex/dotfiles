// Copied to the root of a config copy by scripts/bottom-bar-render.sh.
import QtQuick
import Quickshell
import "config"
import "bar/bottombar"

ShellRoot {
  FloatingWindow {
    implicitWidth: 1100
    implicitHeight: 170
    color: Colors.surface

    Item {
      id: stage
      width: 1100
      height: 170
      Rectangle { anchors.fill: parent; color: "#101216" }

      BottomBarContent {          // A: idle, full battery, 4 bars, volume 100
        x: 0; y: 0; width: 1100
        items: [
          { appId: "kitty",  pinned: true,  count: 1, windowIds: [3], focused: true,  urgent: false },
          { appId: "firefox", pinned: true, count: 0, windowIds: [],  focused: false, urgent: false },
          { appId: "mpv",    pinned: false, count: 1, windowIds: [7], focused: false, urgent: false }
        ]
        clockText: "0905"; dateText: "07"
        volume: 100; muted: false
        batteryPct: 100; charging: true
        signal: 4; connected: true; vpn: true
        alarmCount: 3
      }
      BottomBarContent {          // B: hover on glance, 40 % battery, 2 bars, muted
        x: 0; y: 85; width: 1100
        items: []
        clockText: "2359"; dateText: "31"
        volume: 40; muted: true
        batteryPct: 40; charging: false
        signal: 2; connected: true; vpn: false
        alarmCount: 0
        forceHover: "glance"
      }
    }

    Timer {
      interval: 2500
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        Qt.quit()
      })
    }
  }
}
