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

  readonly property int neoShadowPadding: Config.neoBrutalism ? Config.themeShadowOffset : 0

  implicitWidth: 280 + neoShadowPadding
  implicitHeight: cardLayout.implicitHeight + Config.spacingExtraLarge + neoShadowPadding
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-toast"
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
      entryAnimation.stop()
      scaleTransform.xScale = 1.0
      scaleTransform.yScale = 1.0
      transX.x = 0
      bg.opacity = 1.0
    } else {
      entryAnimation.start()
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
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      bg.forceActiveFocus()
      root.dismiss()
    }
  }

  Rectangle {
    id: styleShadow
    x: Config.themeShadowOffset
    y: Config.themeShadowOffset
    width: bg.width
    height: bg.height
    radius: bg.radius
    color: Colors.styleShadow
    visible: Config.neoBrutalism
    z: -1
  }

  Rectangle {
    id: bg
    anchors {
      left: parent.left
      top: parent.top
      right: parent.right
      bottom: parent.bottom
      rightMargin: root.neoShadowPadding
      bottomMargin: root.neoShadowPadding
    }
    radius: Config.borderRadius
    activeFocusOnTab: true
    color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
      ? Colors.styleSurface
      : Colors.surfaceContainerHigh
    border.width: Config.themeBorderWidth
    border.color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
      ? Colors.styleOutline
      : Colors.outlineVariant

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
      SpringAnimation {
        target: scaleTransform
        properties: "xScale,yScale"
        from: 0.8
        to: 1.0
        spring: Config.motionSurfaceSpring
        damping: Config.motionSurfaceDamping
        mass: Config.motionSpatialMass
        epsilon: Config.motionSpatialEpsilon
      }
      SpringAnimation {
        target: transX
        property: "x"
        from: 50
        to: 0
        spring: Config.motionSurfaceSpring
        damping: Config.motionSurfaceDamping
        mass: Config.motionSpatialMass
        epsilon: Config.motionSpatialEpsilon
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
          color: Colors.primaryContainer

          Text {
            anchors.centerIn: parent
            text: notif ? (notif.appName.length > 0 ? notif.appName.charAt(0).toUpperCase() : "?") : "?"
            color: Colors.fgPrimaryContainer
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeStrongWeight
          }
        }

        Text {
          text: notif ? (notif.appName || "Notification") : "Notification"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelSmallSize
          font.weight: Config.typeMediumWeight
          font.letterSpacing: Config.typeLabelTracking
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: "now"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelSmallSize
          font.letterSpacing: Config.typeLabelTracking
          opacity: 0.7
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.1)
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
    }
  }
}
