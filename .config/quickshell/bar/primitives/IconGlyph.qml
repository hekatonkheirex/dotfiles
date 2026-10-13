// Shared symbol glyph for Elena controls and indicators.
import QtQuick
import "../../config"

Item {
  id: root

  property string iconLabel: ""
  property string iconFont: Config.iconFont
  property bool iconVariableAxes: true
  property color iconColor: Colors.fgSurface
  property real iconSize: Config.iconSize
  property real iconOpacity: 1.0
  property bool filled: false


  implicitWidth: root.iconSize
  implicitHeight: root.iconSize


  Text {
    anchors.fill: parent
    text: root.iconLabel
    textFormat: Text.PlainText
    color: root.iconColor
    opacity: root.iconOpacity
    font.family: root.iconFont
    font.pixelSize: root.iconSize
    font.weight: Font.Normal
    font.variableAxes: root.iconVariableAxes
      ? Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
      : ({})
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

}
