import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
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
    NumberAnimation { duration: 150 }
  }

  NumberAnimation {
    id: fadeOut
    target: root
    property: "osdOpacity"
    to: 0
    duration: 300
    onStopped: {
      if (root.osdOpacity === 0) root.visible = false
    }
  }

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: fadeOut.start()
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
        console.log("[Antigravity] airplaneQuery finished. muted:", root.muted, "value:", root.value);
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
        console.log("[Antigravity] bluetoothQuery finished. on:", on, "muted:", root.muted, "value:", root.value);
      }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: root.width
    height: root.height
    radius: 16
    opacity: root.osdOpacity
    color: {
      if (!colors_) return Qt.rgba(0.13, 0.13, 0.14, 0.9)
      var c = colors_.surfaceContainerHigh
      return Qt.rgba(c.r, c.g, c.b, 0.92)
    }

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
          return "brightness_high";
        }
        font.family: config ? config.iconFont : "Material Symbols Outlined"
        font.pixelSize: 28
        color: {
          if (root.osdType === "volume") return root.muted ? (colors_ ? colors_.error : "#F2B8B5") : (colors_ ? colors_.primary : "#D0BCFF");
          if (root.osdType === "mic") return root.muted ? (colors_ ? colors_.error : "#F2B8B5") : (colors_ ? colors_.primary : "#D0BCFF");
          if (root.osdType === "airplane") return root.muted ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0");
          if (root.osdType === "bluetooth") return root.muted ? (colors_ ? colors_.error : "#F2B8B5") : (colors_ ? colors_.primary : "#D0BCFF");
          return "#FFD580";
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
          return "";
        }
        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
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
          if (root.osdType === "mic" && root.muted) return colors_ ? colors_.error : "#F2B8B5";
          if (root.osdType === "volume" && root.muted) return colors_ ? colors_.error : "#F2B8B5";
          if (root.osdType === "bluetooth" && root.muted) return colors_ ? colors_.error : "#F2B8B5";
          if (root.osdType === "airplane" && root.muted) return colors_ ? colors_.primary : "#D0BCFF";
          return colors_ ? colors_.fgSurface : "#FFFFFF";
        }
        font.pixelSize: 20
        font.weight: Font.Bold
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width * 0.6
        height: 4
        radius: 2
        color: colors_ ? colors_.surfaceContainerHighest : "#36343B"

        Rectangle {
          width: parent.width * root.value
          height: parent.height
          radius: 2
          color: {
            if (root.muted && (root.osdType === "volume" || root.osdType === "mic")) return colors_ ? colors_.error : "#F2B8B5";
            if (root.osdType === "bluetooth" && root.muted) return colors_ ? colors_.error : "#F2B8B5";
            if (root.osdType === "brightness") return "#FFD580";
            return colors_ ? colors_.primary : "#D0BCFF";
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
