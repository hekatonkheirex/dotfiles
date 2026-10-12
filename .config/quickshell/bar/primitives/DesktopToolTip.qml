import QtQuick
import QtQuick.Controls
import "../../config"

ToolTip {
  id: root
  delay: 600
  timeout: 5000
  closePolicy: Popup.NoAutoClose
  padding: Config.spacingSmall
  implicitWidth: Math.min(360, contentItem.implicitWidth + padding * 2)
  font.family: Config.fontFamily
  font.pixelSize: Config.typeLabelMediumSize
  contentItem: Text {
    text: root.text
    textFormat: Text.PlainText
    font: root.font
    color: Colors.fgSurface
    wrapMode: Text.Wrap
  }
  background: Rectangle {
    radius: Config.shapeCompact
    color: Colors.surfaceContainerHighest
    border.width: 1
    border.color: Colors.styleOutline
  }
}
