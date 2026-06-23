import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property QtObject notificationServer: null
  property var notif: null
  property int displayMs: config ? config.notificationToastDurationMs : 5000

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
    radius: config ? config.borderRadius : 14
    color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    border.width: 1
    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

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
        duration: 250
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: transX
        property: "x"
        from: 50
        to: 0
        duration: 250
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: bg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 200
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
          color: colors_ ? colors_.primaryContainer : "#4F378B"

          Text {
            anchors.centerIn: parent
            text: notif ? (notif.appName.length > 0 ? notif.appName.charAt(0).toUpperCase() : "?") : "?"
            color: colors_ ? colors_.fgPrimaryContainer : "#EADDFF"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: 10
            font.weight: Font.Bold
          }
        }

        Text {
          text: notif ? (notif.appName || "Notification") : "Notification"
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Roboto"
          font.pixelSize: 11
          font.weight: Font.Medium
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: "now"
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Roboto"
          font.pixelSize: 10
          opacity: 0.7
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.1) : Qt.rgba(255, 255, 255, 0.05)
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          Layout.fillWidth: true
          text: notif ? (notif.summary || "") : ""
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Roboto"
          font.pixelSize: 14
          font.weight: Font.Bold
          elide: Text.ElideRight
          visible: text !== ""
        }

        Text {
          Layout.fillWidth: true
          text: notif ? (notif.body || "") : ""
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Roboto"
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
