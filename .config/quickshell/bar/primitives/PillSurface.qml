import QtQuick
import "../../config"

Item {
  id: root

  property bool horizontal: true
  property bool fitContent: false
  property real contentWidth: 0
  property real contentHeight: 0

  anchors {
    fill: root.fitContent ? null : parent
    centerIn: root.fitContent ? parent : null
    leftMargin: root.fitContent ? 0 : (root.horizontal ? 0 : 6)
    rightMargin: root.fitContent ? 0 : (root.horizontal ? 0 : 6)
    topMargin: root.fitContent ? 0 : (root.horizontal ? 6 : 0)
    bottomMargin: root.fitContent ? 0 : (root.horizontal ? 6 : 0)
  }

  width: root.fitContent
    ? Math.max(0, root.contentWidth - (root.horizontal ? 0 : 12))
    : implicitWidth
  height: root.fitContent ? Math.max(0, root.contentHeight) : implicitHeight
  z: -1

  Rectangle {
    id: shadow
    x: Config.themeShadowOffset
    y: Config.themeShadowOffset
    width: surface.width
    height: surface.height
    radius: surface.radius
    color: Colors.styleShadow
    visible: Config.neoBrutalism
    z: -1
  }

  Rectangle {
    id: surface
    anchors.fill: parent
    radius: Config.ghostTheme
      ? 0
      : (Config.neoBrutalism
        ? Config.shapeMedium
        : (root.horizontal ? height / 2 : width / 2))
    color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
      ? Colors.styleSurface
      : Colors.surfaceContainerHigh
    border.color: Config.neoBrutalism || Config.ghostTheme
      ? Colors.styleOutline
      : (Config.nothingEvolution
        ? Colors.styleOutline
        : (Config.nothingDesign
          ? "transparent"
          : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.18)))
    border.width: Config.neoBrutalism
      ? Config.themeBorderWidth
      : (Config.nothingEvolution ? Config.themeBorderWidth : (Config.nothingDesign ? 0 : 1))
  }
}
