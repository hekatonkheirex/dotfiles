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

  property bool dismissOnAppInactive: true
  // Child popups provide the surface dimensions.
  property real surfaceWidth: Config.popupWidth
  property real surfaceHeight: 0
  // Scale origin of the entry animation: 0 grows from the left edge.
  property real entryOriginX: 0

  property color surfaceColor: Colors.readingSurface
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

  margins.left: Config.barWidth + Config.spacingMedium
  property int screenH: root.screen ? root.screen.height : Screen.desktopAvailableHeight

  anchors.top: true

  onVisibleChanged: {
    if (visible) {
      if (Config.reducedMotion) {
        materialEntryAnimation.stop()
        scaleTransform.xScale = 1.0
        scaleTransform.yScale = 1.0
        transX.x = 0
        bg.opacity = 1.0
      } else {
        materialEntryAnimation.restart()
      }
      shown()
    }
  }

  function dismissIfApplicationInactive() {
    if (root.dismissOnAppInactive && popupFocus.focusAcquired
        && !Qt.application.active && root.visible) root.dismissed()
  }

  Connections {
    target: Qt.application
    function onActiveChanged() {
      if (!Qt.application.active) Qt.callLater(root.dismissIfApplicationInactive)
    }
  }

  FocusScope {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      id: popupFocus
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
      border.color: Colors.outlineVariant

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: root.entryOriginX; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      MaterialEntrance {
        id: materialEntryAnimation
        surfaceTarget: bg
        scaleTarget: scaleTransform
        translationTarget: transX
      }
    }
  }
}
