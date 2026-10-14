import QtQuick
import "../../config"

// Her network-toolbar-button: a 14 S rounded tile with an icon glyph in its
// accent over a small label. `loading` turns the glyph x8 and pulses it
// (still under reduced motion).
Rectangle {
  id: root
  property string glyph: ""
  property string label: ""
  property int accent: 4
  property bool loading: false
  signal clicked()

  implicitWidth: Config.dp(64)
  radius: Config.dp(14)
  color: Colors.surfaceContainer

  Column {
    anchors.centerIn: parent
    Text {
      id: symbol
      objectName: "symbol"
      anchors.horizontalCenter: parent.horizontalCenter
      topPadding: Config.dp(4)
      bottomPadding: Config.dp(4)
      text: root.glyph
      color: Colors.elenaAccent(root.loading ? 8 : root.accent)
      font.family: BottomBarFonts.family
      font.pixelSize: Math.round(12 * 4 / 3 * Config.elenaScale)   // 12pt
      SequentialAnimation on opacity {
        running: root.loading && !Config.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 750 }
        NumberAnimation { to: 1; duration: 750 }
        onRunningChanged: if (!running) symbol.opacity = 1
      }
    }
    Text {
      objectName: "label"
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.label
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Math.round(8 * 4 / 3 * Config.elenaScale)   // 8pt
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
