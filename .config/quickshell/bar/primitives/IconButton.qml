// Theme facade. The concrete Material 3 and Neo Brutalism implementations
// live in separate folders; existing popup call sites keep this stable type.
import QtQml
import QtQuick
import QtQuick.Controls
import "../../config"
import "../themes/material3" as Material3
import "../themes/neo_brutalism" as NeoBrutalism

Item {
  id: root

  property string iconLabel: ""
  property int size: 32
  property int iconSize: 18
  property color iconColor: Colors.fgSurface
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: Config.neoBrutalism ? Colors.styleSurface : "transparent"
  property color borderColor: Colors.styleOutline
  property bool outlined: false
  property bool selected: false
  property real radius: Config.neoBrutalism ? 4 : size / 2
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""

  signal clicked(var mouse)
  signal wheel(var wheel)

  implicitWidth: size
  implicitHeight: size
  activeFocusOnTab: root.enabled

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false

  Loader {
    id: implementation
    anchors.fill: parent
    sourceComponent: Config.neoBrutalism ? neoImplementation : materialImplementation
  }

  Component {
    id: materialImplementation
    Material3.IconButton {}
  }

  Component {
    id: neoImplementation
    NeoBrutalism.IconButton {}
  }

  Binding { target: implementation.item; property: "iconLabel"; value: root.iconLabel }
  Binding { target: implementation.item; property: "size"; value: root.size }
  Binding { target: implementation.item; property: "iconSize"; value: root.iconSize }
  Binding { target: implementation.item; property: "iconColor"; value: root.iconColor }
  Binding { target: implementation.item; property: "hoverColor"; value: root.hoverColor }
  Binding { target: implementation.item; property: "pressColor"; value: root.pressColor }
  Binding { target: implementation.item; property: "backgroundColor"; value: root.backgroundColor }
  Binding { target: implementation.item; property: "borderColor"; value: root.borderColor }
  Binding { target: implementation.item; property: "outlined"; value: root.outlined }
  Binding { target: implementation.item; property: "selected"; value: root.selected }
  Binding { target: implementation.item; property: "radius"; value: root.radius }
  Binding { target: implementation.item; property: "accessibleName"; value: root.accessibleName }
  Binding { target: implementation.item; property: "accessibleDescription"; value: root.accessibleDescription }
  Binding { target: implementation.item; property: "tooltipText"; value: root.tooltipText }
  Binding { target: implementation.item; property: "enabled"; value: root.enabled }
  Binding { target: implementation.item; property: "activeFocusOnTab"; value: root.activeFocusOnTab }

  Connections {
    target: implementation.item
    function onClicked(mouse) { root.clicked(mouse) }
    function onWheel(wheelEvent) { root.wheel(wheelEvent) }
  }
}
