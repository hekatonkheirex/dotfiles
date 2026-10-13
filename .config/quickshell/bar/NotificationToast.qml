import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "primitives"

PanelWindow {
  id: root

  property QtObject notificationServer: null
  property var notif: null
  property var heldNotif: null
  property int displayMs: Settings.notificationToastDurationMs
  property string barPosition: "top"
  // Critical notifications retain a solid error outline and explicit text cue.
  // The "default" action is the click-through apps expect when the notification
  // body is clicked (open the chat, the file, ...). It has no button of its own.
  readonly property var defaultAction: {
    var list = notif && notif.actions ? notif.actions : []
    for (var i = 0; i < list.length; i++)
      if (list[i].identifier === "default") return list[i]
    return null
  }
  readonly property bool critical: !!notif && notif.urgency === NotificationUrgency.Critical

  implicitWidth: 280
  implicitHeight: cardLayout.implicitHeight + Config.spacingExtraLarge
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("toast")
  WlrLayershell.layer: WlrLayer.Top
  anchors.right: true
  anchors.top: Settings.notificationToastPosition !== "bottom-right"
  anchors.bottom: Settings.notificationToastPosition === "bottom-right"
  margins.right: root.barPosition === "right" ? Config.barWidth + Config.spacingCompact : Config.spacingLarge
  margins.top: Settings.notificationToastPosition === "bottom-right" ? 0
    : (root.barPosition === "top" ? Config.barWidth + Config.spacingCompact : Config.spacingLarge)
  margins.bottom: Settings.notificationToastPosition === "bottom-right"
    ? (root.barPosition === "bottom" ? Config.barWidth + Config.spacingCompact : Config.spacingLarge)
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
    if (Config.reducedMotion) {
      materialEntryAnimation.stop()
      scaleTransform.xScale = 1.0
      scaleTransform.yScale = 1.0
      transX.x = 0
      bg.opacity = 1.0
    } else {
      materialEntryAnimation.restart()
    }
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
    enabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      bg.forceActiveFocus()
      if (root.defaultAction) {
        root.defaultAction.invoke()
        root.clearCurrent()
      } else {
        root.dismiss()
      }
    }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Config.popupRadius
    activeFocusOnTab: true
    color: Colors.surface
    border.width: root.critical ? Math.max(2, Config.themeBorderWidth) : 0
    border.color: Colors.error
    DashedFrame { anchors.fill: parent; active: root.visible && !root.critical; radius: bg.radius }

    Accessible.role: Accessible.Button
    Accessible.name: notif ? ((notif.appName || "Notification") + ": "
      + (notif.summary || ("Dismiss notification"))) : "Notification"
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

    MaterialEntrance {
      id: materialEntryAnimation
      surfaceTarget: bg
      scaleTarget: scaleTransform
      translationTarget: transX
      initialScale: Config.toastEntryScale
      initialOffset: Config.toastEntryOffset
    }

    ColumnLayout {
      id: cardLayout
      anchors {
        fill: parent
        leftMargin: Config.spacingLarge
        rightMargin: Config.spacingLarge
        topMargin: Config.spacingMedium
        bottomMargin: Config.spacingMedium
      }
      spacing: Config.spacingSmall

      RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacingSmall

        Rectangle {
          width: 20
          height: 20
          radius: 10
          color: root.critical ? Colors.errorContainer : Colors.primaryContainer
          border.width: 0
          border.color: root.critical ? Colors.destructive : Colors.outline

          Text {
            anchors.centerIn: parent
            text: {
              var app = notif ? (notif.appName || "") : ""
              return app.length > 0 ? app.charAt(0).toUpperCase() : "?"
            }
            color: root.critical
              ? (Colors.fgErrorContainer)
              : (Colors.fgPrimaryContainer)
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeStrongWeight
          }
        }

        Text {
          text: notif ? (notif.appName || "Notification") : "Notification"
          color: Colors.fgSurfaceVariant
          font.family: "monospace"
          font.pixelSize: Config.typeLabelSmallSize
          font.capitalization: Font.AllUppercase
          font.letterSpacing: Config.typeMonoTracking
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: root.critical ? "CRITICAL" : "NOW"
          visible: true
          color: root.critical ? Colors.error : Colors.fgSurfaceVariant
          font.family: "monospace"
          font.pixelSize: Config.typeLabelSmallSize
          font.letterSpacing: Config.typeMonoTracking
          opacity: root.critical ? 1.0 : 0.7
        }
        // Keep the native hit target without enlarging the compact header.
        Item {
          readonly property int visualSize: 28
          implicitWidth: visualSize
          implicitHeight: visualSize
          Layout.alignment: Qt.AlignVCenter

          IconButton {
            anchors.centerIn: parent
            size: parent.visualSize
            iconSize: 14
            iconLabel: "close"
            iconColor: Colors.fgSurfaceVariant
            accessibleName: "Dismiss notification"
            tooltipText: "Dismiss notification"
            onClicked: root.dismiss()
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.1)
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact

        Text {
          Layout.fillWidth: true
          text: notif ? (notif.summary || "") : ""
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleSmallSize
          font.weight: Config.typeStrongWeight
          font.letterSpacing: Config.typeTitleTracking
          lineHeight: Config.typeTitleSmallLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.NoWrap
          maximumLineCount: 1
          elide: Text.ElideRight
          visible: text !== ""
        }

        Text {
          Layout.fillWidth: true
          text: notif ? (notif.body || "") : ""
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodySmallSize
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodySmallLineHeight
          lineHeightMode: Text.FixedHeight
          elide: Text.ElideRight
          maximumLineCount: 3
          wrapMode: Text.WordWrap
          visible: text !== ""
        }
      }

      // App-defined actions (e.g. "Reply", "Open"). The server advertises
      // action support, so each non-default action gets a button. The
      // "default" action is the click-through the toast already replaces with
      // dismiss, so it is not listed.
      Row {
        id: actionRow
        Layout.fillWidth: true
        spacing: Config.spacingSmall
        visible: actionRepeater.count > 0

        Repeater {
          id: actionRepeater
          model: {
            var out = []
            var list = notif && notif.actions ? notif.actions : []
            for (var i = 0; i < list.length && out.length < 3; i++)
              if (list[i].identifier !== "default") out.push(list[i])
            return out
          }

          delegate: ActionButton {
            required property var modelData
            height: implicitHeight
            width: Math.max(72, (actionRow.width - actionRow.spacing * (actionRepeater.count - 1)) / actionRepeater.count)
            labelText: modelData.text
            horizontalContent: true
            variant: "tonal"
            accessibleName: modelData.text
            accessibleDescription: "Notification action"
            onActivated: {
              // invoke() can synchronously close the notification and destroy this delegate.
              var toast = root
              modelData.invoke()
              toast.clearCurrent()
            }
          }
        }
      }
    }
  }
}
