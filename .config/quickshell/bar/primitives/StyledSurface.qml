// Shared surface treatment. Material 3 keeps its tonal surface and outline;
// Neo Brutalism adds the visible hard offset while consuming the same Matugen
// semantic roles for fills, ink, and accents.
import QtQuick
import "../../config"

Item {
  id: root

  property color surfaceColor: Config.nothingEvolution ? Colors.styleSurface : Colors.surfaceContainer
  property color outlineColor: Colors.styleOutline
  property real outlineWidth: Config.themeBorderWidth
  property real radius: Config.shapeLarge
  property bool clipContent: false

  default property alias content: contentLayer.data

  Rectangle {
    id: shadow
    x: Config.themeShadowOffset
    y: Config.themeShadowOffset
    width: root.width
    height: root.height
    radius: root.radius
    color: Colors.styleShadow
    visible: Config.neoBrutalism
    z: -1
  }

  Rectangle {
    id: surface
    anchors.fill: parent
    radius: root.radius
    color: root.surfaceColor
    border.color: root.outlineColor
    border.width: root.outlineWidth
    clip: root.clipContent
  }

  Item {
    id: contentLayer
    anchors.fill: parent
    clip: root.clipContent
  }
}
