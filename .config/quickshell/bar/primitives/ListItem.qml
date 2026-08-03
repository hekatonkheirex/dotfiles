// Dense list row: leading icon, title/subtitle stack, optional selected
// accent, hover overlay, and a trailing slot for status text or actions.
// Lifted out of BtPopup's device-row delegate; Wi-Fi/launcher rows share the
// same shape.
import QtQuick
import QtQuick.Layouts
import "../../config"

Rectangle {
  id: root

  default property alias trailingContent: trailingRow.data

  property string leadingIcon: ""
  property string title: ""
  property string subtitle: ""
  property bool selected: false
  property color leadingIconColor: root.selected ? Colors.primary : Colors.fgSurface
  readonly property alias hovered: itemMouse.containsMouse

  signal clicked(var mouse)

  height: 44
  radius: 12
  color: {
    if (root.selected) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
    return itemMouse.containsMouse ? Qt.tint("transparent", Colors.hoverOverlay) : "transparent"
  }
  border.color: root.selected ? Colors.primary : "transparent"
  border.width: 1

  Behavior on color {
    ColorAnimation { duration: Config.animationDuration }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: 10

    Text {
      visible: root.leadingIcon !== ""
      text: root.leadingIcon
      color: root.leadingIconColor
      font.family: Config.iconFont
      font.pixelSize: 22
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Text {
        Layout.fillWidth: true
        text: root.title
        color: root.selected ? Colors.primary : Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize + 3)
        font.weight: Font.Medium
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize
        elide: Text.ElideRight
      }
    }

    Row {
      id: trailingRow
      spacing: 4
      Layout.alignment: Qt.AlignVCenter
    }
  }

  MouseArea {
    id: itemMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { root.clicked(mouse) }
  }
}
