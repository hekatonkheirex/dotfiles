import QtQuick
import "../../config"

// Her terminal block: a flavor line, then prompt + value + a cursor that
// blinks once per second in two steps.
Column {
  id: root
  property string flavor: ""
  property string prompt: "$ "
  property string value: ""
  property color ink: Colors.elenaAccent(2)
  readonly property int fontSize: Math.round(17 * 4 / 3 * Config.elenaScale)   // 17pt
  spacing: 5

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.flavor
    color: root.ink
    font.family: "monospace"
    font.bold: true
    font.pixelSize: root.fontSize
  }
  Row {
    Text {
      text: root.prompt
      color: root.ink
      font.family: "monospace"
      font.bold: true
      font.pixelSize: root.fontSize
    }
    Text {
      objectName: "terminalValue"
      text: root.value
      color: root.ink
      font.family: "monospace"
      font.bold: true
      font.pixelSize: root.fontSize
    }
    Text {
      id: cursor
      property bool on: true
      text: "_"
      opacity: cursor.on ? 1 : 0
      color: root.ink
      font.family: "monospace"
      font.bold: true
      font.pixelSize: root.fontSize
      Timer {
        interval: 500
        repeat: true
        running: root.visible
        onTriggered: cursor.on = !cursor.on
        onRunningChanged: cursor.on = true
      }
    }
  }
}
