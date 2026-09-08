// Bordered text input: focus-tinted outline, placeholder text, optional
// password masking. Lifted out of the legacy Wi-Fi popup's inline password field so the
// launcher search box and any future form field can share it.
import QtQuick
import QtQuick.Layouts
import "../../config"

Rectangle {
  id: root

  property alias text: input.text
  property string placeholder: ""
  property int echoMode: TextInput.Normal
  property alias input: input
  property string accessibleName: ""
  property string accessibleDescription: ""
  property bool showPlaceholderOnFocus: false
  property bool captureHorizontalArrows: false
  property string leadingIcon: ""
  property color leadingIconColor: Colors.fgSurfaceVariant
  property real leadingIconSize: 22
  readonly property bool material3Style: !Config.nothingDesign
    && !Config.neoBrutalism
    && !Config.ghostTheme

  default property alias trailingContent: trailingRow.data

  signal accepted()
  signal escapePressed()
  signal upPressed()
  signal downPressed()
  signal leftPressed()
  signal rightPressed()

  height: 36
  radius: Config.shapeMedium
  color: root.material3Style ? Colors.surface : Colors.styleSurface
  border.color: root.material3Style
    ? (input.activeFocus ? Colors.primary : Colors.outline)
    : Colors.styleOutlineStrong
  border.width: input.activeFocus ? Config.themeFocusBorderWidth : Config.themeBorderWidth

  RowLayout {
    anchors {
      fill: parent
      leftMargin: Config.spacingMedium
      rightMargin: Config.spacingMedium
    }
    spacing: Config.spacingSmall

    Text {
      visible: root.leadingIcon !== ""
      text: root.leadingIcon
      color: root.leadingIconColor
      font.family: Config.iconFont
      font.pixelSize: root.leadingIconSize
      font.variableAxes: Config.iconVariableAxes(0, root.leadingIconSize)
      Layout.alignment: Qt.AlignVCenter
    }

    TextInput {
      id: input
      Layout.fillWidth: true
      Layout.fillHeight: true
      verticalAlignment: TextInput.AlignVCenter
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyLargeSize
      font.letterSpacing: Config.typeBodyTracking
      echoMode: root.echoMode
      activeFocusOnTab: true
      Accessible.role: Accessible.EditableText
      Accessible.name: root.accessibleName !== ""
        ? root.accessibleName
        : (root.placeholder !== "" ? root.placeholder : "Text field")
      Accessible.description: root.accessibleDescription
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.escapePressed()
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.upPressed()
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.downPressed()
          event.accepted = true
        } else if (event.key === Qt.Key_Left && root.captureHorizontalArrows) {
          root.leftPressed()
          event.accepted = true
        } else if (event.key === Qt.Key_Right && root.captureHorizontalArrows) {
          root.rightPressed()
          event.accepted = true
        }
      }
      onAccepted: root.accepted()

      Text {
        text: root.placeholder
        color: Colors.fgSurfaceVariant
        visible: !parent.text && (!parent.activeFocus || root.showPlaceholderOnFocus)
        font: parent.font
        anchors {
          left: parent.left
          right: parent.right
          verticalCenter: parent.verticalCenter
        }
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    Row {
      id: trailingRow
      spacing: Config.spacingCompact
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
