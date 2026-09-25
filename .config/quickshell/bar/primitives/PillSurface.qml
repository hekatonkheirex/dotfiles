import QtQuick
import "../../config"

Item {
  id: root

  property bool horizontal: true
  property bool fitContent: false
  property real contentWidth: 0
  property real contentHeight: 0
  property real verticalInset: 6
  readonly property bool flatLiquidSurface: Config.liquidGlassTheme && !Colors.liquidGlassOpaque

  anchors {
    fill: root.fitContent ? null : parent
    centerIn: root.fitContent ? parent : null
    leftMargin: root.fitContent ? 0 : (root.horizontal ? 0 : 6)
    rightMargin: root.fitContent ? 0 : (root.horizontal ? 0 : 6)
    topMargin: root.fitContent ? 0 : (root.horizontal ? root.verticalInset : 0)
    bottomMargin: root.fitContent ? 0 : (root.horizontal ? root.verticalInset : 0)
  }

  width: root.fitContent
    ? Math.max(0, root.contentWidth - (root.horizontal ? 0 : 12))
    : implicitWidth
  height: root.fitContent ? Math.max(0, root.contentHeight) : implicitHeight
  z: -1


  Rectangle {
    id: surface
    anchors.fill: parent
    radius: Config.ghostTheme ? 0 : (root.horizontal ? height / 2 : width / 2)
    color: root.flatLiquidSurface ? "transparent"
      : (Config.liquidGlassTheme ? Colors.liquidGlassClear
        : (Config.nothingDesign || Config.ghostTheme ? Colors.styleSurface : Colors.surfaceContainerHigh))
    border.color: root.flatLiquidSurface ? "transparent"
      : (Config.liquidGlassTheme || Config.ghostTheme || Config.nothingEvolution
        ? Colors.styleOutline
        : (Config.nothingDesign ? "transparent"
          : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.18)))
    border.width: root.flatLiquidSurface ? 0
      : (Config.nothingEvolution ? Config.themeBorderWidth : (Config.nothingDesign ? 0 : 1))
  }

  GlassSheen {
    anchors.fill: surface
    radius: surface.radius
    glassEnabled: !root.flatLiquidSurface
  }
}
