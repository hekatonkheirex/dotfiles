// Shared tonal cards; Liquid Glass uses neutral translucent material.
import QtQuick
import "../../config"

Item {
  id: root

  // Material 3 card variants. Outlined remains the compatibility default so
  // existing surfaces keep their current treatment until they opt in.
  property string variant: "outlined"
  property color surfaceColor: Config.material3Theme ? Colors.surface : Colors.styleSurface
  property color outlineColor: Config.material3Theme ? Colors.outlineVariant : Colors.styleOutline
  property real outlineWidth: Config.themeBorderWidth
  property real radius: Config.shapeLarge
  property bool clipContent: false
  readonly property bool material3Theme: Config.material3Theme
  readonly property color liquidGlassSurfaceColor: root.variant === "elevated"
    ? Colors.liquidGlassRaised
    : (root.variant === "filled" ? Colors.liquidGlassRaised : Colors.liquidGlassClear)
  readonly property color renderedSurfaceColor: root.material3Theme
    ? (root.variant === "elevated"
      ? Colors.surfaceContainerLow
      : (root.variant === "filled" ? Colors.surfaceContainerHighest : root.surfaceColor))
    : (Config.liquidGlassTheme ? root.liquidGlassSurfaceColor : root.surfaceColor)
  readonly property color renderedOutlineColor: root.material3Theme && root.variant !== "outlined"
    ? "transparent"
    : root.outlineColor
  readonly property real renderedOutlineWidth: root.material3Theme && root.variant !== "outlined"
    ? 0
    : root.outlineWidth

  default property alias content: contentLayer.data


  Rectangle {
    id: materialElevationShadow
    x: 0
    y: 2
    width: root.width
    height: root.height
    radius: root.radius
    color: Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 0.16)
    visible: root.material3Theme && root.variant === "elevated" && root.width > 0 && root.height > 0
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

  GlassSheen {
    anchors.fill: surface
    radius: surface.radius
    glassEnabled: Config.liquidGlassTheme
  }

  Item {
    id: contentLayer
    anchors.fill: parent
    clip: root.clipContent
  }
}
