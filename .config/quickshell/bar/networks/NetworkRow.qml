import QtQuick
import "../../config"
import "../../config/NetworkList.js" as NetworkList
import "../sidebar"

// One network (her .network): a 6 S left border colored by signal bucket,
// dotted, solid on the connected row; the saved/new type disc; the name cut
// at 22 characters; forget (x3, saved), disconnect (x1, connected) or
// connect (x2) buttons at the right.
Item {
  id: row
  property string name: ""
  property int signal: 0
  property bool active: false
  property bool saved: false

  signal connectClicked()
  signal disconnectClicked()
  signal forgetClicked()

  readonly property string bucket: NetworkList.signalBucket(row.signal)
  readonly property int borderSlot: row.bucket === "ok" ? 3 : row.bucket === "bad" ? 8 : 4
  readonly property var buttons: (row.saved ? ["forget"] : []).concat([row.active ? "disconnect" : "connect"])

  implicitHeight: Config.dp(60)

  Item {
    id: edge
    objectName: "border"
    x: Config.dp(11)
    width: Config.dp(6)
    height: parent.height
    clip: true
    readonly property color tint: Colors.elenaAccent(row.borderSlot)
    // `edge`, not `border`: inside a Rectangle that name is its own border.
    Rectangle { anchors.fill: parent; visible: row.active; color: edge.tint }
    Column {
      visible: !row.active
      spacing: edge.width
      Repeater {
        model: Math.max(0, Math.ceil(edge.height / Config.dp(12)))
        Rectangle { width: edge.width; height: edge.width; color: edge.tint }
      }
    }
  }

  SymbolDisc {
    id: typeDisc
    objectName: "typeDisc"
    x: edge.x + edge.width + Config.dp(11)
    anchors.verticalCenter: parent.verticalCenter
    glyph: row.saved ? "" : ""
  }

  Text {
    objectName: "nameText"
    anchors.left: typeDisc.right
    anchors.leftMargin: Config.dp(11)
    anchors.right: buttonRow.left
    anchors.rightMargin: Config.dp(6)
    anchors.verticalCenter: parent.verticalCenter
    text: NetworkList.shortName(row.name)
    color: Colors.fgSurface
    font.family: Config.fontFamily
    font.pixelSize: Math.round(8 * 4 / 3 * Config.elenaScale)   // 8pt
    elide: Text.ElideRight
  }

  Row {
    id: buttonRow
    anchors.right: parent.right
    anchors.rightMargin: Config.dp(13 + 11)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.dp(11)
    Repeater {
      model: row.buttons
      Rectangle {
        id: btn
        required property string modelData
        objectName: btn.modelData + "Button"
        readonly property int glyphPx: Math.round(10 * 4 / 3 * Config.elenaScale)   // 10pt
        width: btn.glyphPx + 2 * Config.dp(14)
        height: width
        radius: btn.modelData === "connect" ? width / 2 : Config.dp(14)
        color: Colors.surface
        Text {
          anchors.centerIn: parent
          text: btn.modelData === "forget" ? "" : btn.modelData === "disconnect" ? "" : ""
          color: Colors.elenaAccent(btn.modelData === "forget" ? 3 : btn.modelData === "disconnect" ? 1 : 2)
          font.family: BottomBarFonts.family
          font.pixelSize: btn.glyphPx
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (btn.modelData === "forget") row.forgetClicked()
            else if (btn.modelData === "disconnect") row.disconnectClicked()
            else row.connectClicked()
          }
        }
      }
    }
  }
}
