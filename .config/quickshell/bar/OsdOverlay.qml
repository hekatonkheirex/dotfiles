import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../config"

PanelWindow {
  id: root

  property string osdType: ""
  property real value: 0
  property bool muted: false

  implicitWidth: 300
  implicitHeight: 120
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  WlrLayershell.namespace: "quickshell-osd"
  anchors.bottom: true
  margins.bottom: 80

  visible: false

  property real osdOpacity: 0

  Behavior on osdOpacity {
    NumberAnimation { duration: Config.motionMedium}
  }

  NumberAnimation {
    id: fadeOut
    target: root
    property: "osdOpacity"
    to: 0
    duration: (Config.reducedMotion ? 0 : 300)
    onStopped: {
      if (root.osdOpacity === 0) root.visible = false
    }
  }

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: fadeOut.start()
  }

  // ThinkPad keyboard backlight is cycled by the EC firmware itself (Fn+Space
  // never reaches niri/quickshell as a key event). The sysfs brightness value
  // is EC-polled on read rather than push-notified, so inotify never fires;
  // we poll it ourselves inside one persistent process instead.
  Process {
    id: kbdlightWatcher
    command: ["sh", "-c", "prev=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness); while true; do sleep 0.2; cur=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness); if [ $cur != $prev ]; then echo $cur; prev=$cur; fi; done"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        root.show("kbdlight")
      }
    }
    onRunningChanged: {
      if (!running) kbdlightWatcherRetry.start()
    }
  }

  Timer {
    id: kbdlightWatcherRetry
    interval: 1000
    onTriggered: kbdlightWatcher.running = true
  }

  function show(type) {
    osdType = type
    root.osdOpacity = 1
    root.visible = true
    fadeOut.stop()
    hideTimer.restart()
    if (type === "volume") {
      volQuery.running = false
      volQuery.running = true
    } else if (type === "brightness") {
      brightQuery.running = false
      brightQuery.running = true
    } else if (type === "mic") {
      micQuery.running = false
      micQuery.running = true
    } else if (type === "airplane") {
      airplaneQuery.running = false
      airplaneQuery.running = true
    } else if (type === "bluetooth") {
      bluetoothQuery.running = false
      bluetoothQuery.running = true
    } else if (type === "kbdlight") {
      kbdlightQuery.running = false
      kbdlightQuery.running = true
    }
  }

  Process {
    id: volQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.value = parseFloat(m[1])
        root.muted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  Process {
    id: brightQuery
    command: ["brightnessctl", "-m"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.trim().split(",")
        if (parts.length < 5) return
        var pctStr = parts[3].replace("%", "")
        var val = parseFloat(pctStr)
        if (!isNaN(val)) root.value = val / 100
      }
    }
  }

  Process {
    id: micQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        root.muted = out.indexOf("[MUTED]") >= 0
        root.value = root.muted ? 0 : 1
      }
    }
  }

  Process {
    id: airplaneQuery
    command: ["sh", "-c", "nmcli radio wifi | grep -q 'disabled' && echo on || echo off"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.muted = text.trim() === "on"
        root.value = root.muted ? 1 : 0
      }
    }
  }

  Process {
    id: bluetoothQuery
    command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var on = text.trim() === "on"
        root.muted = !on
        root.value = on ? 1 : 0
      }
    }
  }

  Process {
    id: kbdlightQuery
    command: ["brightnessctl", "--class=leds", "-d", "tpacpi::kbd_backlight", "-m"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.trim().split(",")
        if (parts.length < 5) return
        var pctStr = parts[3].replace("%", "")
        var val = parseFloat(pctStr)
        if (!isNaN(val)) root.value = val / 100
      }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: root.width
    height: root.height
    radius: Config.shapeLarge
    opacity: root.osdOpacity
    color: {
      var c = Colors.surfaceContainerHigh
      return Qt.rgba(c.r, c.g, c.b, 0.92)
    }
    border.width: 1
    border.color: Colors.outlineVariant

    Column {
      anchors.centerIn: parent
      spacing: 8

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
          if (root.osdType === "volume") return root.muted ? "volume_off" : (root.value <= 0.01 ? "volume_mute" : (root.value <= 0.3 ? "volume_mute" : (root.value <= 0.7 ? "volume_down" : "volume_up")));
          if (root.osdType === "mic") return root.muted ? "mic_off" : "mic";
          if (root.osdType === "airplane") return root.muted ? "airplanemode_active" : "airplanemode_inactive";
          if (root.osdType === "bluetooth") return root.muted ? "bluetooth_disabled" : "bluetooth";
          if (root.osdType === "kbdlight") return "keyboard";
          return "brightness_high";
        }
        font.family: Config.iconFont
        font.pixelSize: 28
        color: {
          if (root.osdType === "volume") return root.muted ? (Colors.error) : (Colors.primary);
          if (root.osdType === "mic") return root.muted ? (Colors.error) : (Colors.primary);
          if (root.osdType === "airplane") return root.muted ? (Colors.primary) : (Colors.fgSurfaceVariant);
          if (root.osdType === "bluetooth") return root.muted ? (Colors.error) : (Colors.primary);
          if (root.osdType === "kbdlight") return Colors.primary;
          return Colors.brightness;
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
          if (root.osdType === "volume") return "Volume";
          if (root.osdType === "brightness") return "Brightness";
          if (root.osdType === "mic") return "Microphone";
          if (root.osdType === "airplane") return "Airplane Mode";
          if (root.osdType === "bluetooth") return "Bluetooth";
          if (root.osdType === "kbdlight") return "Keyboard Backlight";
          return "";
        }
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 12
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
          if (root.osdType === "mic") return root.muted ? "Muted" : "Unmuted";
          if (root.osdType === "airplane") return root.muted ? "Enabled" : "Disabled";
          if (root.osdType === "bluetooth") return root.muted ? "Disabled" : "Enabled";
          return Math.round(root.value * 100) + "%";
        }
        color: {
          if (root.osdType === "mic" && root.muted) return Colors.error;
          if (root.osdType === "volume" && root.muted) return Colors.error;
          if (root.osdType === "bluetooth" && root.muted) return Colors.error;
          if (root.osdType === "airplane" && root.muted) return Colors.primary;
          return Colors.fgSurface;
        }
        font.family: Config.fontFamily
        font.pixelSize: 20
        font.weight: Font.Bold
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width * 0.6
        height: 4
        radius: 2
        color: Colors.surfaceContainerHighest

        Rectangle {
          width: parent.width * root.value
          height: parent.height
          radius: 2
          color: {
            if (root.muted && (root.osdType === "volume" || root.osdType === "mic")) return Colors.error;
            if (root.osdType === "bluetooth" && root.muted) return Colors.error;
            if (root.osdType === "brightness" || root.osdType === "kbdlight") return Colors.brightness;
            return Colors.primary;
          }
        }
      }
    }
  }

  onVisibleChanged: {
    if (!visible) {
      root.osdOpacity = 0
      fadeOut.stop()
      hideTimer.stop()
    }
  }
}
