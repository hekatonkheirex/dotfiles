import QtQuick
import "../../config"
import "../../config/NetworkList.js" as NetworkList

// Inline passphrase entry for a new secured network (her rofi prompt
// "Enter passphrase >"): masked, Enter submits, Esc cancels. Opening it
// clears the field and takes focus.
Rectangle {
  id: root
  property string name: ""
  signal submitted(string password)
  signal cancelled()

  implicitHeight: Config.dp(44)
  radius: Config.dp(8)
  color: Colors.surfaceContainer

  onVisibleChanged: if (visible) { field.text = ""; field.forceActiveFocus() }

  Text {
    id: prompt
    anchors.left: parent.left
    anchors.leftMargin: Config.dp(11)
    anchors.verticalCenter: parent.verticalCenter
    text: NetworkList.shortName(root.name) + " >"
    color: Colors.elenaAccent(4)
    font.family: Config.fontFamily
    font.pixelSize: Math.round(8 * 4 / 3 * Config.elenaScale)
  }

  TextInput {
    id: field
    objectName: "passInput"
    anchors.left: prompt.right
    anchors.leftMargin: Config.dp(8)
    anchors.right: parent.right
    anchors.rightMargin: Config.dp(11)
    anchors.verticalCenter: parent.verticalCenter
    echoMode: TextInput.Password
    clip: true
    color: Colors.fgSurface
    font.family: Config.fontFamily
    font.pixelSize: Math.round(10 * 4 / 3 * Config.elenaScale)
    Keys.onReturnPressed: root.submitted(field.text)
    Keys.onEnterPressed: root.submitted(field.text)
    Keys.onEscapePressed: function(event) { event.accepted = true; root.cancelled() }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: field.text === ""
      text: "passphrase"
      color: Colors.elenaAccent(8)
      font: field.font
    }
  }
}
