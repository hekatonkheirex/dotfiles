import QtQuick
import QtQuick.Controls
import "../../config"

ScrollBar {
  id: root

  property var scrollTarget: null
  readonly property bool overflowing: root.scrollTarget !== null
    && root.scrollTarget.contentHeight > root.scrollTarget.height

  width: 4
  z: 10
  policy: ScrollBar.AlwaysOn
  minimumSize: Math.min(1, Config.spacingExtraLarge / Math.max(1, root.height))

  background: Rectangle {
    anchors.fill: parent
    implicitWidth: 4
    radius: width / 2
    color: "transparent"
  }

  contentItem: Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    y: root.visualPosition * root.height
    height: root.visualSize * root.height
    visible: root.overflowing
    implicitWidth: 4
    implicitHeight: Config.spacingExtraLarge
    radius: width / 2
    color: Colors.primary
    opacity: root.pressed ? 1.0 : 0.78
  }
}
