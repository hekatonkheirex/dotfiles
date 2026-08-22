// Theme facade. Concrete Material 3, Neo Brutalism, Nothing, and Ghost
// implementations live in separate folders; existing bar call sites keep this
// stable type.
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"
import "../themes/material3" as Material3
import "../themes/neo_brutalism" as NeoBrutalism
import "../themes/nothing" as Nothing
import "../themes/ghost" as Ghost

Item {
  id: root

  property string iconLabel: ""
  property bool selected: false
  property string labelText: ""
  property string variant: "tonal"
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  readonly property bool filled: root.selected || root.variant === "filled"
  property real iconSize: Config.iconSize + 4
  property color iconColor: root.filled ? Colors.styleAccentText : Colors.fgSurfaceVariant
  property real radius: Config.nothingDesign
    ? Config.shapeCompact
    : (Config.neoBrutalism ? 4 : Config.shapeMedium)
  property color color: {
    var overlay = root.pressed ? Colors.pressOverlay
      : (root.hovered ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.filled
      ? Colors.styleAccent
      : (root.variant === "quiet"
        ? ((Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme) ? Colors.styleSurface : "transparent")
        : ((Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme) ? Colors.styleSurfaceRaised : Colors.surfaceContainer))
    return Qt.tint(base, overlay)
  }
  property color borderColor: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
    ? Colors.styleOutlineStrong
    : (root.filled || root.variant === "quiet"
      ? "transparent"
      : (root.variant === "outlined" ? Colors.styleOutlineStrong
        : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)))
  property real borderWidth: Config.neoBrutalism ? Config.themeBorderWidth : 1

  signal activated()

  activeFocusOnTab: true
  Layout.minimumHeight: Config.themeActionButtonMinHeight > 0
    && root.iconLabel !== ""
    && root.labelText !== ""
    ? Config.themeActionButtonMinHeight
    : 0

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
    Material3.ActionButton {}
  }

  Component {
    id: neoImplementation
    NeoBrutalism.ActionButton {}
  }

  Component {
    id: nothingImplementation
    Nothing.ActionButton {}
  }

  Component {
    id: ghostImplementation
    Ghost.ActionButton {}
  }

  Binding { target: implementation.item; property: "iconLabel"; value: root.iconLabel }
  Binding { target: implementation.item; property: "selected"; value: root.selected }
  Binding { target: implementation.item; property: "labelText"; value: root.labelText }
  Binding { target: implementation.item; property: "variant"; value: root.variant }
  Binding { target: implementation.item; property: "accessibleName"; value: root.accessibleName }
  Binding { target: implementation.item; property: "accessibleDescription"; value: root.accessibleDescription }
  Binding { target: implementation.item; property: "tooltipText"; value: root.tooltipText }
  Binding { target: implementation.item; property: "iconSize"; value: root.iconSize }
  Binding { target: implementation.item; property: "iconColor"; value: root.iconColor }
  Binding { target: implementation.item; property: "radius"; value: root.radius }
  Binding { target: implementation.item; property: "color"; value: root.color }
  Binding { target: implementation.item; property: "borderColor"; value: root.borderColor }
  Binding { target: implementation.item; property: "borderWidth"; value: root.borderWidth }
  Binding { target: implementation.item; property: "enabled"; value: root.enabled }
  Binding { target: implementation.item; property: "activeFocusOnTab"; value: root.activeFocusOnTab }

  Connections {
    target: implementation.item
    function onActivated() { root.activated() }
  }
}
