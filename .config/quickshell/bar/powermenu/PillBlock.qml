import QtQuick
import "../../config"

// Red pill and blue pill, tilted outlines in the slot the cat used to fill.
// The pill under the pointer fills solid; `hovered` names it ("red", "blue"
// or ""). Same 64 x 69 slot as before so the panel layout does not move.
Item {
  id: root
  objectName: "pillBlock"
  readonly property string hovered: redPill.area.containsMouse ? "red"
    : bluePill.area.containsMouse ? "blue" : ""
  implicitWidth: Config.dp(64)
  implicitHeight: implicitWidth * 69 / 64

  component Pill: Item {
    id: pill
    property color ink
    property bool filled: false
    property alias area: area
    width: root.width * 18 / 64
    height: root.width * 42 / 64
    Rectangle {
      anchors.fill: parent
      radius: width / 2
      border.width: Math.max(1, Math.round(root.width * 1.5 / 64))
      border.color: pill.ink
      color: pill.filled ? pill.ink : "transparent"
      Behavior on color {
        enabled: !Config.reducedMotion
        ColorAnimation { duration: 150 }
      }
    }
    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }
  }

  Pill {
    id: redPill
    objectName: "pillRed"
    x: root.width * 15 / 64 - width / 2
    y: root.height / 2 - height / 2
    rotation: -14
    ink: Colors.elenaAccent(1)
    filled: root.hovered === "red"
  }
  Pill {
    id: bluePill
    objectName: "pillBlue"
    x: root.width * 49 / 64 - width / 2
    y: root.height / 2 - height / 2
    rotation: 14
    ink: Colors.elenaAccent(3)
    filled: root.hovered === "blue"
  }
}
