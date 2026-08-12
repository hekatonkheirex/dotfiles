// Dense list row: leading icon, title/subtitle stack, optional selected
// accent, hover/focus state layers, and a trailing slot for status text or actions.
// Lifted out of the legacy Bluetooth popup's device-row delegate; Wi-Fi/launcher rows share the
// same shape.
import QtQuick
import QtQuick.Layouts
import "../../config"

Rectangle {
  id: root

  default property alias trailingContent: trailingRow.data

  property string leadingIcon: ""
  property real leadingIconOpacity: 1.0
  property string leadingImageSource: ""
  property string leadingFallbackText: ""
  property string title: ""
  property string subtitle: ""
  property bool selected: false
  property bool navigationFocused: false
  property color leadingIconColor: root.selected ? Colors.primary : Colors.fgSurface
  property string accessibleName: ""
  property string accessibleDescription: ""
  readonly property bool hovered: itemMouse.containsMouse
  readonly property bool pressed: itemMouse.pressed

  signal clicked(var mouse)

  height: 44
  radius: Config.shapeMedium
  activeFocusOnTab: root.enabled
  opacity: root.enabled ? 1.0 : 0.38

  Accessible.role: Accessible.ListItem
  Accessible.name: root.accessibleName !== "" ? root.accessibleName : root.title
  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.selected ? root.subtitle + " Selected" : root.subtitle)
  Accessible.selected: root.selected
  Accessible.selectable: true
  Accessible.focusable: root.activeFocusOnTab
  Accessible.focused: root.activeFocus || root.navigationFocused

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.clicked(null)
      event.accepted = true
    }
  }
  color: {
    if (root.selected) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
    if (root.navigationFocused) return Qt.tint("transparent", Colors.focusOverlay)
    if (itemMouse.containsMouse) return Qt.tint("transparent", Colors.hoverOverlay)
    return root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
  }
  border.color: root.selected ? Colors.primary : "transparent"
  border.width: 1

  Behavior on color {
    ColorAnimation { duration: Config.animationDuration }
  }

  // Keep the row hit target below its content so trailing controls can still
  // receive clicks. Non-interactive text falls through to this MouseArea.
  MouseArea {
    id: itemMouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.forceActiveFocus()
      root.clicked(mouse)
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: Config.spacingSmall

    Text {
      visible: root.leadingIcon !== "" && root.leadingImageSource === ""
      text: root.leadingIcon
      color: root.leadingIconColor
      opacity: root.leadingIconOpacity
      font.family: Config.iconFont
      font.pixelSize: Config.iconSize + 6
    }

    Rectangle {
      visible: root.leadingImageSource !== "" || root.leadingFallbackText !== ""
      width: 30
      height: 30
      radius: 15
      color: Colors.surfaceContainerHigh

      Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        source: root.leadingImageSource
        sourceSize.width: 20
        sourceSize.height: 20
        smooth: true
        fillMode: Image.PreserveAspectFit
        visible: root.leadingImageSource !== ""
      }

      Text {
        anchors.centerIn: parent
        text: root.leadingFallbackText
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.iconSize
        font.weight: Font.Medium
        visible: root.leadingImageSource === "" && root.leadingFallbackText !== ""
      }
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
      spacing: Config.spacingCompact
      Layout.alignment: Qt.AlignVCenter
    }
  }

}
