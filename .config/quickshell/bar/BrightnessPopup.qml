import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 400)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  property real pct: 0

  function setBrightness(val) {
    root.pct = Math.max(0, Math.min(100, val))
    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pct) + "%"])
  }

  Process {
    id: getProc
    command: ["brightnessctl", "-m"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        // format: device,class,current_raw,percentage%,max_raw
        var parts = text.trim().split(",")
        if (parts.length < 5) return
        var pctStr = parts[3].replace("%", "")
        var val = parseFloat(pctStr)
        if (!isNaN(val)) root.pct = val
      }
    }
  }

  function pollBrightness() { getProc.running = true }

  Timer {
    interval: 300
    running: root.visible
    repeat: true
    onTriggered: root.pollBrightness()
  }

  onVisibleChanged: {
    if (root.visible) {
      root.pollBrightness()
      if (config && config.isNiri) root.requestActivate()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      config: root.config
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: config ? config.popupPadding : 16
        }
        spacing: 16

        Text {
          text: "Brightness"
          color: colors_ ? colors_.onSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 8) : 18
          font.weight: Font.Bold
        }

        Text {
          text: Math.round(root.pct) + "%"
          color: colors_ ? colors_.onSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 4) : 14
        }

        SliderControl {
          value: root.pct / 100
          activeColor: colors_ ? colors_.primary : "#D0BCFF"
          surfaceContainerHigh: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
          surfaceContainerHighest: colors_ ? colors_.surfaceContainerHighest : "#36343B"
          outline: colors_ ? colors_.outline : "#938F99"
          onChanged: function(val) { root.setBrightness(val * 100) }
        }
      }
    }
  }
}
