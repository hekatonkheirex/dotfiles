import QtQuick
import "../../config"

Item {
  id: root

  property bool horizontal: true
  property bool fitContent: false
  property real contentWidth: 0
  property real contentHeight: 0
  property real verticalInset: 6

  anchors {
    fill: root.fitContent ? null : parent
    centerIn: root.fitContent ? parent : null
    leftMargin: root.fitContent ? 0 : (root.horizontal ? 0 : 6)
    rightMargin: root.fitContent ? 0 : (root.horizontal ? 0 : 6)
    topMargin: root.fitContent ? 0 : (root.horizontal ? root.verticalInset : 0)
    bottomMargin: root.fitContent ? 0 : (root.horizontal ? root.verticalInset : 0)
  }

  width: root.fitContent
    ? Math.max(0, root.contentWidth - (root.horizontal ? 0 : 12))
    : implicitWidth
  height: root.fitContent ? Math.max(0, root.contentHeight) : implicitHeight
  z: -1


  Rectangle {
    id: surface
    anchors.fill: parent
    radius: (root.horizontal ? height / 2 : width / 2)
    color: Colors.surfaceContainerHigh
    border.color: ((Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)))
    border.width: ((1))
  }

}
