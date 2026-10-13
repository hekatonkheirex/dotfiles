import QtQuick
import "../../config"
import "../../config/BottomBarModel.js" as BottomBarModel

// Three stacked bars: full above half-threshold, half-opacity above the
// lower threshold, empty otherwise (BottomBarModel.batteryParts).
Column {
  id: root
  property real pct: -1
  property color fillColor: Colors.elenaAccent(6)

  spacing: 4
  readonly property var parts: BottomBarModel.batteryParts(root.pct)

  Repeater {
    model: root.parts
    Rectangle {
      required property string modelData
      width: Config.dp(14)
      height: (Config.dp(23) - root.spacing * 2) / 3
      radius: height / 2
      color: modelData === "empty" ? Colors.surfaceContainerHighest : root.fillColor
      opacity: modelData === "half" ? 0.5 : 1
    }
  }
}
