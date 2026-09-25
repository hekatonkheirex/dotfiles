// Theme facade. Material 3, Nothing, and Ghost implementations live in
// separate folders; Liquid Glass reuses Material control geometry.
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"
import "../themes/material3" as Material3
import "../themes/nothing" as Nothing
import "../themes/ghost" as Ghost

Item {
  id: root

  property string iconLabel: ""
  property bool selected: false
  property bool checkable: false
  // Mutually exclusive choices can opt into a connected Material 3 segment.
  property bool grouped: false
  property string groupPosition: "single"
  property string labelText: ""
  property string variant: "tonal"
  // Material 3 standard buttons place a leading icon beside the label. The
  // expressive themes keep their existing stacked treatment by default.
  property bool horizontalContent: Config.material3Theme || Config.liquidGlassTheme
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  // Opt-in only: Material 3 can add an expressive selected-state halo while
  // the other theme implementations keep their native treatment.
  property bool expressiveSelectedShape: false
  readonly property bool material3Theme: Config.material3Theme
  readonly property bool segmented: root.material3Theme
    && root.grouped
    && root.groupPosition !== "single"
  readonly property bool textVariant: root.variant === "text" || root.variant === "quiet"
  readonly property bool filled: root.selected || root.variant === "filled"
  property real iconSize: Config.iconSize + 4
  property real contentSpacing: Config.spacingMedium
  property color iconColor: {
    if (root.segmented) return root.selected ? Colors.fgSecondaryContainer : Colors.fgSurfaceVariant
    if (root.filled) return Config.ghostTheme || Config.nothingDesign || Config.liquidGlassTheme
      ? Colors.styleAccentText : Colors.fgPrimary
    return root.material3Theme && root.variant === "tonal"
      ? Colors.fgSecondaryContainer
      : (root.material3Theme ? Colors.primary : Colors.fgSurfaceVariant)
  }
  property real radius: root.segmented
    ? Math.max(0, root.height / 2)
    : root.grouped
    ? (Config.ghostTheme ? 0 : (root.selected ? Math.max(0, root.height / 2) : Config.shapeCompact))
    : (Config.liquidGlassTheme || Config.nothingDesign
      ? Config.shapeCompact : (root.horizontalContent ? 20 : Config.shapeMedium))
  property color color: {
    var overlay = root.pressed ? Colors.pressOverlay
      : (root.hovered ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base
    if (root.material3Theme) {
      base = root.segmented
        ? (root.selected ? Colors.secondaryContainer : Colors.surfaceContainerLow)
        : (root.filled
          ? Colors.primary
          : (root.textVariant || root.variant === "outlined"
            ? "transparent"
            : (root.variant === "elevated" ? Colors.surfaceContainerLow : Colors.secondaryContainer)))
    } else {
      base = root.filled
        ? Colors.styleAccent
        : (root.textVariant
          ? (Config.liquidGlassTheme && root.variant === "text" ? "transparent" : Colors.styleSurface)
          : (Config.liquidGlassTheme ? Colors.liquidGlassClear : Colors.styleSurfaceRaised))
    }
    return Qt.tint(base, overlay)
  }
  property color borderColor: {
    if (root.material3Theme) {
      return root.segmented || (root.variant === "outlined" && !root.filled)
        ? Colors.outline
        : "transparent"
    }
    return Config.nothingDesign || Config.ghostTheme || Config.liquidGlassTheme
      ? Colors.styleOutlineStrong
      : (root.filled || root.textVariant
        ? "transparent"
        : (root.variant === "outlined" ? Colors.styleOutlineStrong
          : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)))
  }
  property real borderWidth: 1

  signal activated()

  activeFocusOnTab: true
  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.activated()
      event.accepted = true
    }
  }
  Layout.minimumHeight: 0

  readonly property bool hovered: implementation.item ? implementation.item.hovered : false
  readonly property bool pressed: implementation.item ? implementation.item.pressed : false

  Loader {
    id: implementation
    anchors.fill: parent
    sourceComponent: Config.ghostTheme ? ghostImplementation
      : (Config.nothingDesign ? nothingImplementation : materialImplementation)
  }

  Component {
    id: materialImplementation
    Material3.ActionButton {}
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
    when: root.material3Theme && implementation.item !== null
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

  Connections {
    target: implementation.item
    function onActivated() { root.activated() }
  }
}
