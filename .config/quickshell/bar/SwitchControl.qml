import QtQml
import QtQuick
import QtQuick.Layouts
import "../config"
import "controls"

FocusScope {
  id: root

  property bool checked: false
  property color activeColor: Colors.primary
  property color activeContentColor: Colors.fgPrimary
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.outline
  property color focusColor: Colors.primary
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  property int motionDuration: Config.controlMotionDuration
  property bool reducedMotion: false
  property string accessibleName: "Switch"
  property string accessibleDescription: "Toggle setting"

  signal toggled()

  function activate() {
    if (root.enabled) root.toggled()
  }

  width: 52
  height: Config.controlHitSize
  implicitWidth: 52
  implicitHeight: Config.controlHitSize
  Layout.minimumWidth: Config.controlHitSize
  Layout.minimumHeight: Config.controlHitSize
  activeFocusOnTab: true

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false
  readonly property bool active: implementation.item ? implementation.item.active : false

  Loader {
    id: implementation
    focus: true
    anchors.fill: parent
    sourceComponent: elenaImplementation
  }

  Component {
    id: elenaImplementation
    ElenaSwitchControl {}
  }

  Binding { target: implementation.item; property: "checked"; value: root.checked }
  Binding { target: implementation.item; property: "activeColor"; value: root.activeColor }
  Binding { target: implementation.item; property: "activeContentColor"; value: root.activeContentColor }
  Binding { target: implementation.item; property: "checkmarkColor"; value: root.checkmarkColor }
  Binding { target: implementation.item; property: "surfaceContainerHigh"; value: root.surfaceContainerHigh }
  Binding { target: implementation.item; property: "surfaceContainerHighest"; value: root.surfaceContainerHighest }
  Binding { target: implementation.item; property: "outline"; value: root.outline }
  Binding { target: implementation.item; property: "focusColor"; value: root.focusColor }
  Binding { target: implementation.item; property: "hoverOverlay"; value: root.hoverOverlay }
  Binding { target: implementation.item; property: "pressOverlay"; value: root.pressOverlay }
  Binding { target: implementation.item; property: "motionDuration"; value: root.motionDuration }
  Binding { target: implementation.item; property: "reducedMotion"; value: root.reducedMotion }
  Binding { target: implementation.item; property: "accessibleName"; value: root.accessibleName }
  Binding { target: implementation.item; property: "accessibleDescription"; value: root.accessibleDescription }
  Binding { target: implementation.item; property: "enabled"; value: root.enabled }
  Binding { target: implementation.item; property: "activeFocusOnTab"; value: root.activeFocusOnTab }
  Binding { target: implementation.item; property: "focus"; value: true }

  Connections {
    target: implementation.item
    function onToggled() { root.toggled() }
  }
}
