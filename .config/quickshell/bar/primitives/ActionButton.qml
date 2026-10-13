import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"
import "../controls"

FocusScope {
  id: root

  property string iconLabel: ""
  property bool selected: false
  property bool checkable: false
  // Mutually exclusive choices can opt into a connected Material 3 segment.
  property bool grouped: false
  property string groupPosition: "single"
  property string labelText: ""
  property string variant: "tonal"
  // Standard buttons place a leading icon beside the label.
  property bool horizontalContent: true
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  // Opt-in only: adds an expressive selected-state halo.
  property bool expressiveSelectedShape: false
  readonly property bool segmented: root.grouped && root.groupPosition !== "single"
  readonly property bool textVariant: root.variant === "text" || root.variant === "quiet"
  readonly property bool filled: root.selected || root.variant === "filled" || root.variant === "pill"
  property real iconSize: Config.iconSize + 4
  property real contentSpacing: Config.spacingMedium
  property color iconColor: {
    if (root.segmented) return root.selected ? Colors.fgSecondaryContainer : Colors.fgSurfaceVariant
    if (root.filled) return Colors.fgPrimary
    return root.variant === "tonal" ? Colors.fgSecondaryContainer : Colors.primary
  }
  property real radius: root.variant === "pill" ? root.height / 2 : Config.shapeLarge
  property color color: {
    var overlay = root.pressed ? Colors.pressOverlay
      : (root.hovered ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.segmented
      ? (root.selected ? Colors.secondaryContainer : Colors.surfaceContainerLow)
      : (root.filled
        ? Colors.primary
        : (root.textVariant || root.variant === "outlined"
          ? "transparent"
          : (root.variant === "elevated" ? Colors.surfaceContainerLow : Colors.secondaryContainer)))
    return Qt.tint(base, overlay)
  }
  property color borderColor: root.segmented || (root.variant === "outlined" && !root.filled)
    ? Colors.outline
    : "transparent"
  property real borderWidth: 1

  signal activated()

  activeFocusOnTab: true
  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.activated()
      event.accepted = true
    }
  }
  implicitHeight: Math.max(Config.controlHitSize, Config.typeLabelMediumLineHeight + 24)
  Layout.minimumHeight: implicitHeight
  Layout.minimumWidth: Config.controlHitSize

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
    ElenaActionButton {}
  }

  Binding { target: implementation.item; property: "iconLabel"; value: root.iconLabel }
  Binding { target: implementation.item; property: "selected"; value: root.selected }
  Binding { target: implementation.item; property: "checkable"; value: root.checkable }
  Binding {
    target: implementation.item
    property: "grouped"
    value: root.grouped
    when: implementation.item !== null
  }
  Binding { target: implementation.item; property: "groupPosition"; value: root.groupPosition }
  Binding { target: implementation.item; property: "labelText"; value: root.labelText }
  Binding { target: implementation.item; property: "variant"; value: root.variant }
  Binding { target: implementation.item; property: "horizontalContent"; value: root.horizontalContent }
  Binding { target: implementation.item; property: "accessibleName"; value: root.accessibleName }
  Binding { target: implementation.item; property: "accessibleDescription"; value: root.accessibleDescription }
  Binding { target: implementation.item; property: "tooltipText"; value: root.tooltipText }
  Binding {
    target: implementation.item
    property: "expressiveSelectedShape"
    value: root.expressiveSelectedShape
    when: implementation.item !== null
  }
  Binding { target: implementation.item; property: "iconSize"; value: root.iconSize }
  Binding { target: implementation.item; property: "contentSpacing"; value: root.contentSpacing }
  Binding { target: implementation.item; property: "iconColor"; value: root.iconColor }
  Binding { target: implementation.item; property: "radius"; value: root.radius }
  Binding { target: implementation.item; property: "color"; value: root.color }
  Binding { target: implementation.item; property: "borderColor"; value: root.borderColor }
  Binding { target: implementation.item; property: "borderWidth"; value: root.borderWidth }
  Binding { target: implementation.item; property: "enabled"; value: root.enabled }
  Binding { target: implementation.item; property: "activeFocusOnTab"; value: root.activeFocusOnTab }
  Binding { target: implementation.item; property: "focus"; value: true }

  Connections {
    target: implementation.item
    function onActivated() { root.activated() }
  }
}
