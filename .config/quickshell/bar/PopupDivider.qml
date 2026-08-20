import QtQuick
import "../config"

Item {
  id: root

  width: parent ? parent.width : 0
  height: 1

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)
  }
}
