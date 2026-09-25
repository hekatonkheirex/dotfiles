import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "primitives"

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
  // Child popups provide the surface dimensions.
  property real surfaceWidth: Config.popupWidth
  property real surfaceHeight: 0
  property color surfaceColor: Colors.chromeSurface
  readonly property alias bg: bg
  default property alias content: bg.data

  signal dismissed()
  signal shown()

  implicitWidth: surfaceWidth
  implicitHeight: surfaceHeight
  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("popup")
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true

  anchors.left: true
  // Nothing and Ghost pills need more clearance than the nominal bar width.
  margins.left: (!Settings.fullBar && (Config.nothingDesign || Config.ghostTheme)
    ? Config.barWidth + 18 : Config.barWidth) + Config.spacingMedium
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(topMarginFloor, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight - bottomMarginPad))

  onVisibleChanged: {
    if (visible) {
      if (Config.reducedMotion) {
        entryAnimation.stop()
        reducedMotionEntryAnimation.stop()
        scaleTransform.xScale = 1.0
        scaleTransform.yScale = 1.0
        transX.x = 0
        if (Config.liquidGlassTheme) {
          bg.opacity = 0.0
          reducedMotionEntryAnimation.start()
        } else {
          bg.opacity = 1.0
        }
      } else {
        entryAnimation.start()
      }
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
      radius: Config.popupRadius
      color: root.surfaceColor
      clip: true
      border.width: Config.themeBorderWidth
      border.color: Config.nothingDesign || Config.ghostTheme || Config.liquidGlassTheme
        ? Colors.styleOutline
        : Colors.outlineVariant

      GlassSheen {
        anchors.fill: parent
        radius: parent.radius
      }

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: Config.surfaceEntryScale
          to: 1.0
          duration: Config.surfaceEntryDuration
          easing.type: Config.themeMotionEasing
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: Config.surfaceEntryOffset
          to: 0
          duration: Config.surfaceEntryDuration
          easing.type: Config.themeMotionEasing
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: Config.surfaceOpacityDuration
          easing.type: Easing.OutCubic
        }
      }

      NumberAnimation {
        id: reducedMotionEntryAnimation
        target: bg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: Config.reducedMotionFadeDuration
        easing.type: Easing.OutCubic
      }
    }
  }
}
