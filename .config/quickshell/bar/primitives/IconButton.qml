// Theme facade. Concrete Material 3, Neo Brutalism, Nothing, and Ghost
// implementations live in separate folders; existing popup call sites keep
// this stable type.
import QtQml
import QtQuick
import QtQuick.Controls
import "../../config"
import "../themes/material3" as Material3
import "../themes/neo_brutalism" as NeoBrutalism
import "../themes/nothing" as Nothing
import "../themes/ghost" as Ghost

Item {
  id: root

  property string iconLabel: ""
  property int size: 32
  property int iconSize: 18
  property string variant: "standard"
  readonly property bool material3Theme: !Config.nothingDesign && !Config.neoBrutalism && !Config.ghostTheme
  property color iconColor: {
    if (!root.material3Theme) return root.selected ? Colors.styleAccentText : Colors.fgSurface
    if (root.selected) return Colors.fgPrimary
    return root.variant === "filled"
      ? Colors.fgSurface
      : (root.variant === "tonal" ? Colors.fgSecondaryContainer : Colors.fgSurfaceVariant)
  }
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: {
    if (!root.material3Theme) return Config.neoBrutalism ? Colors.styleSurface : "transparent"
    if (root.selected) return Colors.primary
    return root.variant === "filled"
      ? Colors.surfaceContainerHighest
      : (root.variant === "tonal" ? Colors.secondaryContainer : "transparent")
  }
  property color borderColor: root.material3Theme ? Colors.outline : Colors.styleOutline
  property bool outlined: root.variant === "outlined" && !root.selected
  property bool selected: false
  property bool checkable: false
  property real radius: Config.nothingDesign
    ? Config.shapeCompact
    : (Config.neoBrutalism ? 4 : size / 2)
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
    sourceComponent: Config.ghostTheme
      ? ghostImplementation
      : (Config.nothingDesign
        ? nothingImplementation
        : (Config.neoBrutalism ? neoImplementation : materialImplementation))
  }

  Component {
    id: materialImplementation
    Material3.IconButton {}
  }

  Component {
    id: neoImplementation
    NeoBrutalism.IconButton {}
  }

  Component {
    id: nothingImplementation
    Nothing.IconButton {}
  }

  Component {
    id: ghostImplementation
    Ghost.IconButton {}
  }

  Binding { target: implementation.item; property: "iconLabel"; value: root.iconLabel }
  Binding { target: implementation.item; property: "size"; value: root.size }
  Binding { target: implementation.item; property: "variant"; value: root.variant }
  Binding { target: implementation.item; property: "iconSize"; value: root.iconSize }
  Binding { target: implementation.item; property: "iconColor"; value: root.iconColor }
  Binding { target: implementation.item; property: "hoverColor"; value: root.hoverColor }
  Binding { target: implementation.item; property: "pressColor"; value: root.pressColor }
  Binding { target: implementation.item; property: "backgroundColor"; value: root.backgroundColor }
  Binding { target: implementation.item; property: "borderColor"; value: root.borderColor }
  Binding { target: implementation.item; property: "outlined"; value: root.outlined }
  Binding { target: implementation.item; property: "selected"; value: root.selected }
  Binding { target: implementation.item; property: "checkable"; value: root.checkable }
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
