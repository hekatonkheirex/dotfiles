import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../config"
import "primitives"

PanelWindow {
  id: root

  property string osdType: ""
  property real value: 0
  property bool muted: false
  readonly property bool continuous: osdType === "volume" || osdType === "brightness" || osdType === "kbdlight"
  readonly property bool meterVisible: continuous && !(osdType === "volume" && muted)
  readonly property string symbol: {
    if (osdType === "volume") return muted ? "volume_off" : (value <= 0.01 ? "volume_mute" : (value <= 0.3 ? "volume_mute" : (value <= 0.7 ? "volume_down" : "volume_up")))
    if (osdType === "mic") return muted ? "mic_off" : "mic"
    if (osdType === "airplane") return muted ? "airplanemode_active" : "airplanemode_inactive"
    if (osdType === "bluetooth") return muted ? "bluetooth_disabled" : "bluetooth"
    return osdType === "kbdlight" ? "keyboard" : "light_mode"
  }
  readonly property string osdTitle: {
    if (osdType === "volume") return "Volume"
    if (osdType === "brightness") return "Brightness"
    if (osdType === "mic") return "Microphone"
    if (osdType === "airplane") return "Airplane Mode"
    if (osdType === "bluetooth") return "Bluetooth"
    return osdType === "kbdlight" ? "Keyboard Backlight" : ""
  }
  readonly property string readout: {
    if (osdType === "volume" && muted) return "Muted"
    if (osdType === "mic") return muted ? "Muted" : "Unmuted"
    if (osdType === "airplane") return muted ? "Enabled" : "Disabled"
    if (osdType === "bluetooth") return muted ? "Disabled" : "Enabled"
    return Math.round(value * 100) + "%"
  }
  readonly property color signalColor: {
    if ((osdType === "volume" || osdType === "mic" || osdType === "bluetooth") && muted)
      return Colors.error
    if (osdType === "brightness" || osdType === "kbdlight") return Colors.brightness
    return Colors.primary
  }
  readonly property color readoutColor: (osdType === "airplane" && muted)
    || ((osdType === "volume" || osdType === "mic" || osdType === "bluetooth") && muted)
    ? signalColor : Colors.fgSurface

  implicitWidth: ((300))
  implicitHeight: ((120))
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  WlrLayershell.namespace: Config.layerNamespace("osd")
  anchors.bottom: true
  margins.bottom: 80

  visible: false

  property real osdOpacity: 0

  Behavior on osdOpacity {
    NumberAnimation {
      duration: Config.motionMedium
    }
  }

  NumberAnimation {
    id: fadeOut
    target: root
    property: "osdOpacity"
    to: 0
    duration: Config.transientFadeDuration
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
  // we poll it ourselves inside one persistent process instead. The wait is a
  // bash `read -t` timeout, not `sleep`, so each tick forks nothing.
  Process {
    id: kbdlightWatcher
    command: ["bash", "-c", "f=/sys/class/leds/tpacpi::kbd_backlight/brightness; exec {w}<> <(:); read -r prev < \"$f\"; while true; do read -t 0.4 -u $w; read -r cur < \"$f\"; if [ \"$cur\" != \"$prev\" ]; then echo \"$cur\"; prev=$cur; fi; done"]
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
    id: osdSurface
    anchors.fill: parent
    radius: Config.shapeLarge
    opacity: root.osdOpacity
    color: {


      var c = Colors.chromeSurface
      return Qt.rgba(c.r, c.g, c.b, 0.92)
    }
    border.width: Config.themeBorderWidth
    border.color: Colors.outlineVariant




    Column {
      visible: true
      anchors.centerIn: parent
      anchors.verticalCenterOffset: root.meterVisible ? -6 : 0
      spacing: Config.spacingSmall

      IconGlyph {
        anchors.horizontalCenter: parent.horizontalCenter
        iconLabel: root.symbol
        iconSize: 32
        iconColor: root.signalColor
        // The outline sun matches the bar indicator; the filled one is a solid disc.
        filled: osdType !== "brightness"
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.osdTitle
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        font.letterSpacing: Config.typeLabelTracking
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.readout
        color: root.readoutColor
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
      }
    }

    Rectangle {
      visible: root.meterVisible
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 14
      width: parent.width - (48)
      height: ((6))
      radius: (height / 2)
      color: Colors.surfaceContainerHighest

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: parent.radius
        color: root.signalColor
        Behavior on width {
          NumberAnimation { duration: Config.motionShort; easing.type: Easing.OutCubic }
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
