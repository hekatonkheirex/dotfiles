import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"
import "../controls"

FocusScope {
  id: root

  property string iconLabel: ""
  property int size: 32
  property int iconSize: 18
  property string variant: "standard"
  property color iconColor: {
    if (root.selected) return Colors.surface
    return root.variant === "filled"
      ? Colors.fgSurface
      : (root.variant === "tonal" ? Colors.fgSecondaryContainer : Colors.fgSurfaceVariant)
  }
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: {
    if (root.selected) return Colors.primary
    return root.variant === "filled"
      ? Colors.surfaceContainerHighest
      : (root.variant === "tonal" ? Colors.secondaryContainer : "transparent")
  }
  property color borderColor: Colors.outline
  property bool outlined: root.variant === "outlined" && !root.selected
  property bool selected: false
  property bool checkable: false
  property real radius: variant === "round" ? size / 2 : size * 0.34
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""

  signal clicked(var mouse)
  signal wheel(var wheel)

  implicitWidth: Math.max(Config.controlHitSize, size)
  implicitHeight: Math.max(Config.controlHitSize, size)
  Layout.minimumWidth: Config.controlHitSize
  Layout.minimumHeight: Config.controlHitSize
  activeFocusOnTab: root.enabled

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false

  Loader {
    id: implementation
    focus: true
    anchors.fill: parent
    sourceComponent: elenaImplementation
  }

  Component {
    id: elenaImplementation
    ElenaIconButton {}
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
  Binding { target: implementation.item; property: "focus"; value: true }

  Connections {
    target: implementation.item
    function onClicked(mouse) { root.clicked(mouse) }
    function onWheel(wheelEvent) { root.wheel(wheelEvent) }
  }
}
