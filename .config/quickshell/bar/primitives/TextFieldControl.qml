// Bordered text input: focus-tinted outline, placeholder text, optional
// password masking. Lifted out of WifiPopup's inline password field so the
// launcher search box and any future form field can share it.
import QtQuick
import "../../config"

Rectangle {
  id: root

  property alias text: input.text
  property string placeholder: ""
  property int echoMode: TextInput.Normal
  property alias input: input

  signal accepted()

  height: 36
  radius: 8
  color: Colors.surface
  border.color: input.activeFocus ? Colors.primary : Colors.outline
  border.width: input.activeFocus ? 2 : 1

  TextInput {
    id: input
    anchors {
      fill: parent
      leftMargin: 10
      rightMargin: 10
    }
    verticalAlignment: TextInput.AlignVCenter
    color: Colors.fgSurface
    font.family: Config.fontFamily
    font.pixelSize: Config.fontPixelSize + 2
    echoMode: root.echoMode
    onAccepted: root.accepted()

    Text {
      text: root.placeholder
      color: Colors.fgSurfaceVariant
      visible: !parent.text && !parent.activeFocus
      font: parent.font
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
