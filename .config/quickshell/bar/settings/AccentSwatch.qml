import QtQuick
import "../../config"

// One round palette swatch: a toggle for the shortlist, or a radio for the
// active accent. `ring` marks the current choice, `mark` shows a check.
FocusScope {
  id: root

  property color swatchColor: Colors.primary
  property bool ring: false
  property bool mark: false
  property string label: ""
  property string description: ""
  signal activated()

  implicitWidth: 40
  implicitHeight: 40
  width: implicitWidth
  height: implicitHeight
  activeFocusOnTab: root.enabled
  opacity: root.enabled ? 1 : 0.4

  Accessible.role: Accessible.Button
  Accessible.name: root.label
  Accessible.description: root.description
  Accessible.checked: root.ring || root.mark
  Accessible.onPressAction: root.activated()

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: root.swatchColor
    border.width: root.ring ? 3 : 1
    border.color: root.ring ? Colors.fgSurface : Colors.outlineVariant
    Behavior on border.width { NumberAnimation { duration: Config.motionShort } }

    Text {
      anchors.centerIn: parent
      visible: root.mark
      text: "✓"
      color: Colors.fgSurface
      font.pixelSize: 18
      font.weight: Font.Bold
      style: Text.Outline
      styleColor: root.swatchColor
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: -4
      radius: width / 2
      color: "transparent"
      border.width: root.activeFocus ? 2 : 0
      border.color: Colors.primary
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }

  Keys.onReturnPressed: root.activated()
  Keys.onSpacePressed: root.activated()
}
