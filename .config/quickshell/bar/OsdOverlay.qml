import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../config"
import "primitives"
import "sidebar"

PanelWindow {
  id: root

  property string osdType: ""
  property real value: 0
  property bool muted: false
  readonly property bool continuous: osdType === "volume" || osdType === "brightness" || osdType === "kbdlight"
  readonly property bool meterVisible: continuous && !(osdType === "volume" && muted)
  // Volume and brightness use her icomoon glyphs (same as the sidebar tiles).
  // The rest have no glyph in her fonts and keep Material Symbols, like the
  // sidebar weather disc.
  readonly property bool materialGlyph: osdType !== "volume" && osdType !== "brightness" && osdType !== "kbdlight"
  readonly property string symbol: {
    if (osdType === "volume") return "\uef74"
    if (osdType === "brightness" || osdType === "kbdlight") return "\ue983"
    if (osdType === "mic") return muted ? "mic_off" : "mic"
    if (osdType === "airplane") return muted ? "airplanemode_active" : "airplanemode_inactive"
    if (osdType === "bluetooth") return muted ? "bluetooth_disabled" : "bluetooth"
    return ""
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
  // Her slider colors: volume x5, brightness x1, off states x8 (SliderTile).
  readonly property bool off: (osdType === "volume" || osdType === "mic" || osdType === "bluetooth") && muted
  readonly property color signalColor: off ? Colors.elenaAccent(8) : Colors.elenaAccent(accentSlot)
  readonly property int accentSlot: osdType === "volume" ? 5
    : (osdType === "mic" ? 2 : (osdType === "bluetooth" || osdType === "airplane" ? 4 : 1))
  readonly property int pad: Config.dp(8) + Config.dp(16)   // frame + inner padding
  readonly property int textPx: Math.round(12 * 4 / 3 * Config.elenaScale)

  implicitWidth: Config.dp(340)
  implicitHeight: Config.dp(112)
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  WlrLayershell.namespace: Config.layerNamespace("osd")
  anchors.bottom: true
  // Above the 48 px bottom bar.
  margins.bottom: Config.bottomBarHeight + Config.dp(20)

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

  // Same card as the toasts: solid surface in a surfaceContainer frame.
  Rectangle {
    id: osdSurface
    objectName: "osdSurface"
    anchors.fill: parent
    radius: Config.dp(18)
    opacity: root.osdOpacity
    color: Colors.surface
    border.width: Config.dp(8)
    border.color: Colors.surfaceContainer

    SymbolDisc {
      id: disc
      objectName: "osdDisc"
      x: root.pad
      anchors.verticalCenter: parent.verticalCenter
      width: Config.dp(46)
      color: root.signalColor
      glyph: root.symbol
      family: root.materialGlyph ? Config.iconFont : BottomBarFonts.family
      glyphSize: Math.round(14 * 4 / 3 * Config.elenaScale)
    }

    Column {
      x: root.pad + disc.width + Config.dp(14)
      width: parent.width - x - root.pad
      anchors.verticalCenter: parent.verticalCenter
      spacing: Config.dp(10)

      Row {
        width: parent.width
        Text {
          objectName: "osdTitle"
          width: parent.width - readoutText.implicitWidth
          text: root.osdTitle
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: root.textPx
          elide: Text.ElideRight
        }
        Text {
          id: readoutText
          objectName: "osdReadout"
          text: root.readout
          color: root.off ? root.signalColor : Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: root.textPx
        }
      }

      Rectangle {
        objectName: "osdMeter"
        visible: root.meterVisible
        width: parent.width
        height: Config.dp(10)
        radius: height / 2
        color: Colors.surfaceContainerHighest

        Rectangle {
          objectName: "osdFill"
          width: parent.width * Math.max(0, Math.min(1, root.value))
          height: parent.height
          radius: parent.radius
          color: root.signalColor
          Behavior on width {
            enabled: !Config.reducedMotion
            NumberAnimation { duration: Config.motionShort; easing.type: Easing.OutCubic }
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
