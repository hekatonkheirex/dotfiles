import QtQml
import QtQuick
import "../config"
import "controls"

FocusScope {
  id: root

  property real value: 0.5
  property bool muted: false
  property color activeColor: Colors.primary
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.outline
  property color focusColor: Colors.primary
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  property int motionDuration: Config.controlMotionDuration
  property bool reducedMotion: false
  property real stepSize: 0.05
  property string accessibleName: "Slider"
  property string accessibleDescription: "Adjust value"
  property real accessibleMinimumValue: 0
  property real accessibleMaximumValue: 100
  property string accessibleUnit: "%"

  signal changed(real value)
  signal interactionFinished()

  implicitWidth: 240
  height: 40
  activeFocusOnTab: true

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false
  readonly property bool active: implementation.item ? implementation.item.active : false
  function clearFocus() {
    root.focus = false
  }

  Loader {
    id: implementation
    focus: true
    anchors.fill: parent
    sourceComponent: elenaImplementation
  }

  Component {
    id: elenaImplementation
    ElenaSliderControl {}
  }

  Binding { target: implementation.item; property: "value"; value: root.value }
  Binding { target: implementation.item; property: "muted"; value: root.muted }
  Binding { target: implementation.item; property: "activeColor"; value: root.activeColor }
  Binding { target: implementation.item; property: "surfaceContainerHigh"; value: root.surfaceContainerHigh }
  Binding { target: implementation.item; property: "surfaceContainerHighest"; value: root.surfaceContainerHighest }
  Binding { target: implementation.item; property: "outline"; value: root.outline }
  Binding { target: implementation.item; property: "focusColor"; value: root.focusColor }
  Binding { target: implementation.item; property: "hoverOverlay"; value: root.hoverOverlay }
  Binding { target: implementation.item; property: "pressOverlay"; value: root.pressOverlay }
  Binding { target: implementation.item; property: "motionDuration"; value: root.motionDuration }
  Binding { target: implementation.item; property: "reducedMotion"; value: root.reducedMotion }
  Binding { target: implementation.item; property: "stepSize"; value: root.stepSize }
  Binding { target: implementation.item; property: "accessibleName"; value: root.accessibleName }
  Binding { target: implementation.item; property: "accessibleDescription"; value: root.accessibleDescription }
  Binding { target: implementation.item; property: "accessibleMinimumValue"; value: root.accessibleMinimumValue }
  Binding { target: implementation.item; property: "accessibleMaximumValue"; value: root.accessibleMaximumValue }
  Binding { target: implementation.item; property: "accessibleUnit"; value: root.accessibleUnit }
  Binding { target: implementation.item; property: "enabled"; value: root.enabled }
  Binding { target: implementation.item; property: "activeFocusOnTab"; value: root.activeFocusOnTab }
  Binding { target: implementation.item; property: "focus"; value: true }

  Connections {
    target: implementation.item
    function onChanged(nextValue) { root.changed(nextValue) }
    function onInteractionFinished() { root.interactionFinished() }
  }
}
