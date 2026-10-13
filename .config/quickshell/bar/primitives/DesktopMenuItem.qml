import QtQuick
import QtQuick.Controls
import "../../config"

MenuItem {
  id: root
  implicitWidth: Math.max(220, contentItem.implicitWidth + leftPadding + rightPadding)
  implicitHeight: Config.controlHitSize
  leftPadding: Config.spacingMedium
  rightPadding: Config.spacingMedium
  font.family: Config.fontFamily
  font.pixelSize: Config.typeLabelLargeSize
  contentItem: Text {
    text: root.text
    textFormat: Text.PlainText
    font: root.font
    color: root.enabled ? Colors.fgSurface : Colors.fgSurfaceVariant
    opacity: root.enabled ? 1 : 0.38
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  background: Rectangle {
    radius: Config.shapeCompact
    color: root.highlighted ? Qt.tint(Colors.surfaceContainerHigh, Colors.hoverOverlay) : "transparent"
    border.width: root.activeFocus ? 1 : 0
    border.color: Colors.primary
  }
  HoverHandler { cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
