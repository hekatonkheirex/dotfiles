import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

// Shared chrome for bar-anchored popups: layer-shell window setup, edge
// anchoring, escape/focus-loss dismissal, and the shared entry transform/fade.
// Each popup supplies its own content as children (forwarded into `bg`) and
// still owns its own `surfaceHeight` binding, since the padding and cap vary
// per popup.
PanelWindow {
  id: root

  property int anchorY: 0
  property int topMarginFloor: 0
  property int bottomMarginPad: 0
  property bool dismissOnAppInactive: true
  // Child popups provide the surface dimensions; Neo adds an outer inset so
  // the hard offset remains inside the layer-shell window bounds.
  property real surfaceWidth: Config.popupWidth
  property real surfaceHeight: 0
  readonly property int neoShadowPadding: Config.neoBrutalism ? Config.themeShadowOffset : 0
  readonly property alias bg: bg
  default property alias content: bg.data

  signal dismissed()
  signal shown()

  implicitWidth: surfaceWidth + neoShadowPadding
  implicitHeight: surfaceHeight + neoShadowPadding
  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true

  anchors.left: true
  // Match the actual rendered bar/pill thickness, not the base bar size:
  // Nothing and Neo's pills-mode panel is wider than Config.barWidth, and a
  // flat offset made popups overlap the bar's own widgets.
  margins.left: (!Settings.fullBar && (Config.neoBrutalism || Config.nothingDesign)
    ? Config.barWidth + (Config.neoBrutalism ? 2 : 18)
    : Config.barWidth) + Config.spacingMedium
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
      color: Config.neoBrutalism || Config.nothingDesign
        ? Colors.styleSurface
        : Colors.surfaceContainerHigh
      clip: true
      border.width: Config.themeBorderWidth
      border.color: Colors.styleOutline

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
          easing.type: Config.themeMotionEasing
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: Config.motionLong
          easing.type: Config.themeMotionEasing
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
