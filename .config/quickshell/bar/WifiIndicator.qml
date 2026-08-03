import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

Item {
  id: root


  property bool active: false
  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: Config.widgetSize
  Layout.preferredHeight: Config.widgetSize

  property bool wifiOn: false
  property int wifiSignal: -1

  // Use the standard "wifi" icon which is guaranteed to exist and render perfectly.
  readonly property string iconLabel: "wifi"

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
          if (!isNaN(sig)) {
            root.wifiSignal = sig
          } else {
            root.wifiSignal = -1
          }
        } else {
          root.wifiSignal = -1
        }
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 10000 // 10s
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: wifiQuery.running = true
  }

  Timer {
    id: refreshTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (root.visible) wifiQuery.running = true
    }
  }

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: root.horizontal ? height / 2 : width / 2
    clip: true
    color: {
      var overlay = mouseArea.pressed ? Colors.pressOverlay : (mouseArea.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
      return Qt.tint(root.active ? Colors.primary : Colors.surfaceContainerHigh, overlay)
    }
    border.color: {
      if (root.active) return "transparent"
      return Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration}
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return Colors.fgPrimary
      return Colors.primary
    }
    opacity: {
      if (!root.wifiOn) return 0.25
      if (root.wifiSignal < 0) return 0.4
      if (root.wifiSignal <= 25) return 0.55
      if (root.wifiSignal <= 50) return 0.7
      if (root.wifiSignal <= 75) return 0.85
      return 1.0
    }
    font.family: Config.iconFont
    font.pixelSize: Config.iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4
    text: root.wifiOn && root.wifiSignal >= 0 ? root.wifiSignal + "%" : "--%"
    color: {
      if (root.active) return Colors.fgPrimary
      return Colors.primary
    }
    opacity: {
      if (!root.wifiOn) return 0.35
      if (root.wifiSignal < 0) return 0.5
      return 1.0
    }
    font.family: Config.fontFamily
    font.pixelSize: (Config.fontPixelSize - 2)
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
