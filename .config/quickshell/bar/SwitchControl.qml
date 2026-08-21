// Theme facade. Concrete Material 3, Neo Brutalism, and Nothing switches live in
// separate folders while this interface remains stable for existing callers.
import QtQml
import QtQuick
import "../config"
import "themes/material3" as Material3
import "themes/neo_brutalism" as NeoBrutalism
import "themes/nothing" as Nothing

Item {
  id: root

  property bool checked: false
  property color activeColor: Colors.primary
  property color activeContentColor: Colors.styleAccentText
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.styleOutlineStrong
  property color focusColor: activeColor
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  property int motionDuration: 150
  property bool reducedMotion: false
  property string accessibleName: "Switch"
  property string accessibleDescription: "Toggle setting"

  signal toggled()

  width: 52
  height: 32
  activeFocusOnTab: true

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false
  readonly property bool active: implementation.item ? implementation.item.active : false

  Loader {
    id: implementation
    anchors.fill: parent
    sourceComponent: Config.nothingDesign
      ? nothingImplementation
      : (Config.neoBrutalism ? neoImplementation : materialImplementation)
  }

  Component {
    id: materialImplementation
    Material3.SwitchControl {}
  }

  Component {
    id: neoImplementation
    NeoBrutalism.SwitchControl {}
  }

  Component {
    id: nothingImplementation
    Nothing.SwitchControl {}
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

  Connections {
    target: implementation.item
    function onToggled() { root.toggled() }
  }
}
