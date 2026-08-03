import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"

PanelWindow {
  id: root

  property QtObject notificationServer: null
  property var notif: null
  property int displayMs: Config.notificationToastDurationMs

  implicitWidth: 280
  implicitHeight: cardLayout.implicitHeight + 24
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-toast"
  anchors.right: true
  anchors.top: true
  margins.right: 16
  margins.top: 16
  visible: notif !== null

  function show(n) {
    if (notif !== null) {
      dismissTimer.stop()
      notif = null
    }
    notif = n
    dismissTimer.restart()
    entryAnimation.start()
  }

  function dismiss() {
    if (!notif) return
    notif.dismiss()
    notif = null
  }

  Timer {
    id: dismissTimer
    interval: root.displayMs
    onTriggered: {
      if (!root.notif) return
      root.notif = null
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.dismiss()
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Config.borderRadius
    color: Colors.surfaceContainerHigh
    border.width: 1
    border.color: Colors.outlineVariant

    transform: [
      Translate { id: transX; x: 0 },
      Scale { id: scaleTransform; origin.x: bg.width; origin.y: 0; xScale: 1.0; yScale: 1.0 }
    ]

    ParallelAnimation {
      id: entryAnimation
      NumberAnimation {
        target: scaleTransform
        properties: "xScale,yScale"
        from: 0.8
        to: 1.0
        duration: Config.motionLong
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: transX
        property: "x"
        from: 50
        to: 0
        duration: Config.motionLong
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: bg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: Config.motionMedium
        easing.type: Easing.OutCubic
      }
    }

    ColumnLayout {
      id: cardLayout
      anchors {
        fill: parent
        leftMargin: 16
        rightMargin: 16
        topMargin: 12
        bottomMargin: 12
      }
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          width: 20
          height: 20
          radius: 10
          color: Colors.primaryContainer

          Text {
            anchors.centerIn: parent
            text: notif ? (notif.appName.length > 0 ? notif.appName.charAt(0).toUpperCase() : "?") : "?"
            color: Colors.fgPrimaryContainer
            font.family: Config.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
          }
        }

        Text {
          text: notif ? (notif.appName || "Notification") : "Notification"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: 11
          font.weight: Font.Medium
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: "now"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: 10
          opacity: 0.7
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.1)
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          Layout.fillWidth: true
          text: notif ? (notif.summary || "") : ""
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: 14
          font.weight: Font.Bold
          elide: Text.ElideRight
          visible: text !== ""
        }

        Text {
          Layout.fillWidth: true
          text: notif ? (notif.body || "") : ""
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: 12
          elide: Text.ElideRight
          maximumLineCount: 3
          wrapMode: Text.WordWrap
          visible: text !== ""
        }
      }
    }
  }
}
