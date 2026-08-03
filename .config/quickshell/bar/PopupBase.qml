import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

// Shared chrome for bar-anchored popups: layer-shell window setup, edge
// anchoring, escape/focus-loss dismissal, and the M3 entry transform/fade.
// Each popup supplies its own content as children (forwarded into `bg`) and
// still owns its own `implicitHeight` binding, since the padding and cap
// vary per popup.
PanelWindow {
  id: root

  property int anchorY: 0
  property int topMarginFloor: 0
  property int bottomMarginPad: 0
  property bool dismissOnAppInactive: true
  readonly property alias bg: bg
  default property alias content: bg.data

  signal dismissed()
  signal shown()

  implicitWidth: Config.popupWidth
  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true

  anchors.left: true
  margins.left: Config.barWidth + 4
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(topMarginFloor, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight - bottomMarginPad))

  onVisibleChanged: {
    if (visible) {
      entryAnimation.start()
      shown()
    }
  }

  Connections {
    target: Qt.application
    function onActiveChanged() {
      if (root.dismissOnAppInactive && !Qt.application.active && root.visible) root.dismissed()
    }
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: Config.borderRadius
      color: Colors.surfaceContainerHigh
      clip: true
      border.width: 1
      border.color: Colors.outlineVariant

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: Config.motionLong
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
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
    }
  }
}
