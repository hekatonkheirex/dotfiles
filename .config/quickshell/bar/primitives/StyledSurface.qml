
import QtQuick
import "../../config"

Item {
  id: root

  // Material 3 card variants. Outlined remains the compatibility default so
  // existing surfaces keep their current treatment until they opt in.
  property string variant: "outlined"
  // Settings groups use a quieter surface and fine outline, without changing
  // the shell's unrelated popup and dashboard cards.
  property bool settingsSection: false
  property color surfaceColor: Colors.surface
  property color outlineColor: Colors.outlineVariant
  property real outlineWidth: Config.themeBorderWidth
  property real radius: Config.shapeLarge
  property bool clipContent: false
  readonly property color renderedSurfaceColor: (root.variant === "elevated"
      ? Colors.surfaceContainerLow
      : (root.variant === "filled"
        ? (root.settingsSection ? Colors.surfaceContainer : Colors.surfaceContainerHighest)
        : root.surfaceColor))
  readonly property color renderedOutlineColor: root.settingsSection && root.variant === "filled"
    ? Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.25)
    : (root.variant !== "outlined" ? "transparent" : root.outlineColor)
  readonly property real renderedOutlineWidth: root.settingsSection && root.variant === "filled"
    ? 1 : (root.variant !== "outlined" ? 0 : root.outlineWidth)

  default property alias content: contentLayer.data


  Rectangle {
    id: materialElevationShadow
    x: 0
    y: 2
    width: root.width
    height: root.height
    radius: root.radius
    color: Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 0.16)
    visible: root.variant === "elevated" && root.width > 0 && root.height > 0
    z: -1
  }

  Rectangle {
    id: surface
    anchors.fill: parent
    radius: root.radius
    color: root.renderedSurfaceColor
    border.color: root.renderedOutlineColor
    border.width: root.renderedOutlineWidth
    clip: root.clipContent
  }


  Item {
    id: contentLayer
    anchors.fill: parent
    clip: root.clipContent
  }
}
