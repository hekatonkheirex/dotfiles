import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

PanelWindow {
  id: root

  property QtObject notificationServer: null
  property var notif: null
  property var heldNotif: null
  property int displayMs: Settings.notificationToastDurationMs
  property string barPosition: "top"

  implicitWidth: 280
  implicitHeight: cardLayout.implicitHeight + 24
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-toast"
  WlrLayershell.layer: WlrLayer.Top
  anchors.right: true
  anchors.top: Settings.notificationToastPosition !== "bottom-right"
  anchors.bottom: Settings.notificationToastPosition === "bottom-right"
  margins.right: root.barPosition === "right" ? Config.barWidth + 4 : 16
  margins.top: Settings.notificationToastPosition === "bottom-right" ? 0
    : (root.barPosition === "top" ? Config.barWidth + 4 : 16)
  margins.bottom: Settings.notificationToastPosition === "bottom-right"
    ? (root.barPosition === "bottom" ? Config.barWidth + 4 : 16)
    : 0
  visible: notif !== null

  function isPersistent(n) {
    return n && (n.urgency === NotificationUrgency.Critical || n.expireTimeout === 0)
  }

  function show(n) {
    if (Settings.doNotDisturb
        && !(Settings.notificationCriticalBypass && n && n.urgency === NotificationUrgency.Critical)) return
    if (notif !== null && notif !== n && isPersistent(notif))
      heldNotif = notif
    if (heldNotif === n)
      heldNotif = null
    dismissTimer.stop()
    notif = null
    notif = n
    if (!isPersistent(n))
      dismissTimer.restart()
    entryAnimation.start()
  }

  // DND hides the toast surface without dismissing the notification itself;
  // the notification remains available in the history popup.
  function suppress() {
    dismissTimer.stop()
    notif = null
    heldNotif = null
  }

  function clearCurrent() {
    dismissTimer.stop()
    if (!notif) return
    notif = null
    if (heldNotif) {
      var held = heldNotif
      heldNotif = null
      show(held)
    }
  }

  function dismiss() {
    if (!notif) return
    var current = notif
    clearCurrent()
    current.dismiss()
  }

  Timer {
    id: dismissTimer
    interval: root.displayMs
    running: root.notif !== null && !root.isPersistent(root.notif)
    onTriggered: {
      root.clearCurrent()
    }
  }

  Connections {
    target: root.notif
    function onClosed() { root.clearCurrent() }
  }

  Connections {
    target: root.heldNotif
    function onClosed() { root.heldNotif = null }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      bg.forceActiveFocus()
      root.dismiss()
    }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Config.borderRadius
    activeFocusOnTab: true
    color: Colors.surfaceContainerHigh
    border.width: 1
    border.color: Colors.outlineVariant

    Accessible.role: Accessible.Button
    Accessible.name: notif ? ((notif.appName || "Notification") + ": " + (notif.summary || "Dismiss notification")) : "Notification"
    Accessible.description: "Dismiss notification"

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.dismiss()
        event.accepted = true
      }
    }

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
