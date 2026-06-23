import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  property bool active: false
  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

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
      if (root.active) return colors_ ? colors_.primary : "#D0BCFF"
      if (mouseArea.containsMouse) return colors_ ? colors_.surfaceContainerHighest : "#36343B"
      return colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    }
    border.color: {
      if (root.active) return "transparent"
      return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
    }
    opacity: {
      if (!root.wifiOn) return 0.25
      if (root.wifiSignal < 0) return 0.4
      if (root.wifiSignal <= 25) return 0.55
      if (root.wifiSignal <= 50) return 0.7
      if (root.wifiSignal <= 75) return 0.85
      return 1.0
    }
    font.family: config ? config.iconFont : "Material Symbols Outlined"
    font.pixelSize: config ? config.iconSize : 22
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4
    text: root.wifiOn && root.wifiSignal >= 0 ? root.wifiSignal + "%" : "--%"
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
    }
    opacity: {
      if (!root.wifiOn) return 0.35
      if (root.wifiSignal < 0) return 0.5
      return 1.0
    }
    font.family: config ? config.fontFamily : "Roboto"
    font.pixelSize: config ? (config.fontPixelSize - 2) : 8
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
