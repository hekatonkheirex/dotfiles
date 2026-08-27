import QtQuick
import "../../config"

// Non-interactive separator for dense, homogeneous lists. Insets keep the
// rule aligned with the text column instead of cutting through leading icons.
Item {
  id: root

  property int insetStart: 0
  property int insetEnd: 0
  readonly property bool material3Style: !Config.nothingDesign
    && !Config.neoBrutalism
    && !Config.ghostTheme
  property color dividerColor: root.material3Style
    ? Colors.outlineVariant
    : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g,
        Colors.styleOutlineStrong.b, 0.18)

  width: parent ? parent.width : 0
  height: 1
  implicitHeight: 1

  Rectangle {
    x: Math.max(0, root.insetStart)
    width: Math.max(0, root.width - Math.max(0, root.insetStart)
      - Math.max(0, root.insetEnd))
    height: root.height
    color: root.dividerColor
  }
}
