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
  implicitHeight: layout.implicitHeight + 24
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
    anchors.fill: parent
    radius: config ? config.borderRadius : 14
    color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"

    RowLayout {
      id: layout
      anchors {
        fill: parent
        margins: 12
      }
      spacing: 10

      Rectangle {
        width: 32
        height: 32
        radius: 16
        color: colors_ ? colors_.primaryContainer : "#4F378B"

        Text {
          anchors.centerIn: parent
          text: notif ? (notif.appName.length > 0 ? notif.appName.charAt(0).toUpperCase() : "?") : "?"
          color: colors_ ? colors_.onPrimaryContainer : "#EADDFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: 18
          font.weight: Font.Bold
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: notif ? (notif.appName || "Unknown") : ""
          color: colors_ ? colors_.onSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: 15
          font.weight: Font.Medium
          elide: Text.ElideRight
        }

        Text {
          text: notif ? (notif.summary || "") : ""
          color: colors_ ? colors_.onSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: 14
          font.weight: Font.Bold
          elide: Text.ElideRight
          visible: text !== ""
        }

        Text {
          text: notif ? (notif.body || "") : ""
          color: colors_ ? colors_.onSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: 13
          elide: Text.ElideRight
          maximumLineCount: 2
          wrapMode: Text.WordWrap
          visible: text !== ""
        }
      }


    }
  }
}
