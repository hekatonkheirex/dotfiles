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
  // R6c: her rofi inputbar. `plain` drops the outline; the glyph comes from her
  // icon font; padding and entry font are tunable.
  property bool plain: false
  property string leadingGlyph: ""
  property color leadingGlyphColor: Colors.fgSurface
  property real leadingGlyphSize: 20
  property real sidePadding: Config.spacingMedium
  property real verticalPadding: 6
  property real textPixelSize: Config.typeBodyMediumSize
  property bool textBold: false

  default property alias trailingContent: trailingRow.data

  signal accepted()
  signal escapePressed()
  signal upPressed()
  signal downPressed()
  signal leftPressed()
  signal rightPressed()

  implicitHeight: Math.max(root.plain ? 0 : Config.controlHeight,
    Math.round(root.textPixelSize * 1.5) + 2 * root.verticalPadding)
  height: implicitHeight
  Layout.minimumHeight: implicitHeight
  radius: root.plain ? 0 : Config.shapeMedium
  color: Colors.surface
  border.color: (input.activeFocus ? Colors.primary : Colors.outline)
  border.width: root.plain ? 0 : (input.activeFocus ? Config.themeFocusBorderWidth : Config.themeBorderWidth)


  RowLayout {
    anchors {
      fill: parent
      leftMargin: root.sidePadding
      rightMargin: root.sidePadding
    }
    spacing: Config.spacingSmall

    Text {
      visible: root.leadingGlyph !== ""
      text: root.leadingGlyph
      color: root.leadingGlyphColor
      font.family: BottomBarFonts.family
      font.pixelSize: root.leadingGlyphSize
      Layout.alignment: Qt.AlignVCenter
    }

    IconGlyph {
      visible: root.leadingIcon !== ""
      iconLabel: root.leadingIcon
      iconColor: root.leadingIconColor
      iconSize: root.leadingIconSize
      Layout.alignment: Qt.AlignVCenter
    }

    TextInput {
      id: input
      Layout.fillWidth: true
      Layout.fillHeight: true
      verticalAlignment: TextInput.AlignVCenter
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: root.textPixelSize
      font.bold: root.textBold
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
