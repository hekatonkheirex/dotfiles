// Theme facade. Concrete Material 3, Neo Brutalism, Nothing, and Ghost sliders
// live in separate folders while this interface remains stable for callers.
import QtQml
import QtQuick
import "../config"
import "themes/material3" as Material3
import "themes/neo_brutalism" as NeoBrutalism
import "themes/nothing" as Nothing
import "themes/ghost" as Ghost

Item {
  id: root

  property real value: 0.5
  property bool muted: false
  readonly property bool material3Theme: !Config.nothingDesign && !Config.neoBrutalism && !Config.ghostTheme
  property color activeColor: Colors.primary
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: root.material3Theme ? Colors.outline : Colors.styleOutlineStrong
  property color focusColor: root.material3Theme ? Colors.primary : activeColor
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  property int motionDuration: 150
  property bool reducedMotion: false
  property real stepSize: 0.05
  property string accessibleName: "Slider"
  property string accessibleDescription: "Adjust value"
  property real accessibleMinimumValue: 0
  property real accessibleMaximumValue: 100
  property string accessibleUnit: "%"

  signal changed(real value)
  signal interactionFinished()

  width: parent ? parent.width : 240
  height: 40
  activeFocusOnTab: true

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false
  readonly property bool active: implementation.item ? implementation.item.active : false

  Loader {
    id: implementation
    anchors.fill: parent
    sourceComponent: Config.ghostTheme
      ? ghostImplementation
      : (Config.nothingDesign
        ? nothingImplementation
        : (Config.neoBrutalism ? neoImplementation : materialImplementation))
  }

  Component {
    id: materialImplementation
    Material3.SliderControl {}
  }

  Component {
    id: neoImplementation
    NeoBrutalism.SliderControl {}
  }

  Component {
    id: nothingImplementation
    Nothing.SliderControl {}
  }

  Component {
    id: ghostImplementation
    Ghost.SliderControl {}
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

  Connections {
    target: implementation.item
    function onChanged(nextValue) { root.changed(nextValue) }
    function onInteractionFinished() { root.interactionFinished() }
  }
}
