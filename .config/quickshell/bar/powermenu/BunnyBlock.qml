import QtQuick
import "../../config"

// Her bunny: three monospace lines, the foot quotes in x1. Hover pats the head.
Item {
  id: root
  readonly property int fontSize: Math.round(17 * 4 / 3 * Config.elenaScale)   // 17pt
  readonly property bool petted: hover.containsMouse
  implicitWidth: lines.implicitWidth
  implicitHeight: lines.implicitHeight

  Column {
    id: lines
    anchors.fill: parent
    spacing: 5
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "(\\ /)  "
      color: Colors.fgSurface
      font.family: "monospace"; font.bold: true; font.pixelSize: root.fontSize
    }
    Text {
      objectName: "bunnyHead"
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.petted ? "( ^ ^) " : "( . .) "
      color: Colors.fgSurface
      font.family: "monospace"; font.bold: true; font.pixelSize: root.fontSize
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      readonly property string q: "<font color=\"" + Colors.elenaAccent(1) + "\">&quot;</font>"
      textFormat: Text.StyledText
      text: "c(" + q + ")(" + q + ")"
      color: Colors.fgSurface
      font.family: "monospace"; font.bold: true; font.pixelSize: root.fontSize
    }
  }

  MouseArea {
    id: hover
    objectName: "bunnyHover"
    // Hover only: clicks fall through to the dismiss area below.
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
