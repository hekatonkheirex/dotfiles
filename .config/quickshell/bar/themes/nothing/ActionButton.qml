import QtQuick
import QtQuick.Controls
import "../../../config"
import "."

Item {
  id: root

  ThemeTokens { id: theme }

  property string iconLabel: ""
  property bool selected: false
  property bool checkable: false
  property bool grouped: false
  property string groupPosition: "single"
  property string labelText: ""
  property string variant: "tonal"
  property bool horizontalContent: false
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  property bool expressiveSelectedShape: false
  readonly property bool filled: root.selected || root.variant === "filled"
  property real iconSize: Config.iconSize + 4
  property real contentSpacing: Config.spacingMedium
  property color iconColor: root.filled ? theme.accentText : theme.mutedInk
  property real radius: theme.controlRadius
  property color color: {
    var overlay = mouseArea.pressed ? Colors.pressOverlay
      : (mouseArea.containsMouse ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.filled
      ? theme.accent
      : (root.variant === "quiet" ? "transparent" : theme.surface)
    return Qt.tint(base, overlay)
  }
  property color borderColor: theme.outline
  property real borderWidth: theme.borderWidth

  signal activated()

  activeFocusOnTab: true
  opacity: root.enabled ? 1.0 : 0.38

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  Accessible.role: root.grouped && root.checkable
    ? Accessible.RadioButton
    : (root.checkable ? Accessible.CheckBox : Accessible.Button)
  Accessible.checkable: root.checkable
  Accessible.checked: root.checkable && root.selected
  Accessible.name: root.accessibleName !== ""
    ? root.accessibleName
    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel))
  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.selected ? "Selected" : "")

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: root.color
    border.color: root.borderColor
    border.width: root.borderWidth
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 1
    height: 2
    color: theme.signalColor
    visible: root.selected && root.labelText === ""
  }

  Behavior on color {
    ColorAnimation { duration: Config.animationDuration }
  }

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.activated()
      event.accepted = true
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: root.labelText !== "" ? root.contentSpacing : 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.iconLabel
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
      font.variableAxes: Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
    }

    Text {
      visible: root.labelText !== ""
      width: Math.max(0, root.width - Config.spacingCompact * 2)
      horizontalAlignment: Text.AlignHCenter
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      color: root.iconColor
      font.family: theme.monoFontFamily
      font.pixelSize: Config.typeLabelSmallSize
      font.weight: Config.typeMediumWeight
      font.letterSpacing: Config.typeMonoTracking
      lineHeight: Config.typeLabelSmallLineHeight
      lineHeightMode: Text.FixedHeight
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.forceActiveFocus()
      root.activated()
    }
  }
}
