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
  // Active data rows need a quieter state than selected navigation or expanded rows.
  property bool statusActive: false
  // Material 3 single-select navigation uses a filled container without an outline.
  // Keep this opt-in so generic list rows retain their existing selection states.
  property bool navigationItem: false
  property bool navigationFocused: false
  property int trailingSpacing: Config.spacingCompact
  readonly property bool material3Style: !Config.nothingDesign
    && !Config.neoBrutalism
    && !Config.ghostTheme
  readonly property bool materialNavigationItem: root.navigationItem
    && root.material3Style
  readonly property bool materialStatusItem: root.statusActive
    && !root.selected
    && !root.navigationItem
    && root.material3Style
  readonly property bool stateHighlighted: root.selected || root.statusActive
  readonly property color selectedContainerColor: root.materialNavigationItem
    ? Colors.navigationContainer
    : (root.materialStatusItem
      ? Colors.surfaceContainerHighest
      : (root.material3Style
        ? Colors.secondaryContainer
        : (Config.neoBrutalism || Config.ghostTheme
          ? Colors.styleAccent
          : (Config.nothingDesign
            ? Qt.rgba(Colors.styleAccent.r, Colors.styleAccent.g, Colors.styleAccent.b, 0.16)
            : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)))))
  readonly property color selectedContentColor: root.materialNavigationItem
    ? Colors.navigationContent
    : (root.materialStatusItem
      ? Colors.fgSurface
      : (root.material3Style
        ? Colors.fgSecondaryContainer
        : (Config.neoBrutalism || Config.ghostTheme
          ? Colors.styleAccentText
          : (Config.nothingEvolution
            ? Colors.styleSelectedText
            : (Config.nothingDesign ? Colors.styleInk : Colors.primary)))))
  property color leadingIconColor: root.stateHighlighted
    ? root.selectedContentColor
    : Colors.fgSurface
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
    if (root.stateHighlighted) {
      return root.selectedContainerColor
    }
    if (root.navigationFocused) return Qt.tint("transparent", Colors.focusOverlay)
    if (itemMouse.containsMouse) return Qt.tint("transparent", Colors.hoverOverlay)
    return root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
  }
  border.color: root.materialNavigationItem || root.materialStatusItem
    ? "transparent"
    : (root.material3Style && root.stateHighlighted
      ? "transparent"
      : (Config.neoBrutalism || Config.ghostTheme
        ? Colors.styleOutlineStrong
        : (Config.nothingDesign
          ? (root.stateHighlighted ? Colors.styleOutlineStrong : "transparent")
          : (root.stateHighlighted ? Colors.primary : "transparent"))))
  border.width: root.materialNavigationItem || root.materialStatusItem
    || (root.material3Style && root.stateHighlighted)
    ? 0 : Config.themeBorderWidth

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
    anchors.leftMargin: Config.spacingSmall
    anchors.rightMargin: Config.spacingSmall
    spacing: Config.spacingSmall

    Text {
      visible: root.leadingIcon !== "" && root.leadingImageSource === ""
      text: root.leadingIcon
      color: root.stateHighlighted ? root.selectedContentColor : root.leadingIconColor
      opacity: root.leadingIconOpacity
      font.family: Config.iconFont
      font.pixelSize: Config.iconSize + 6
      font.variableAxes: Config.iconVariableAxes(root.stateHighlighted ? 1 : 0, Config.iconSize + 6)
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
        color: root.stateHighlighted
          ? root.selectedContentColor
          : Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodyLargeSize
        font.weight: Config.typeMediumWeight
        font.letterSpacing: Config.typeBodyTracking
        lineHeight: Config.typeBodyLargeLineHeight
        lineHeightMode: Text.FixedHeight
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        font.letterSpacing: Config.typeLabelTracking
        lineHeight: Config.typeLabelMediumLineHeight
        lineHeightMode: Text.FixedHeight
        elide: Text.ElideRight
      }
    }

    Row {
      id: trailingRow
      spacing: root.trailingSpacing
      Layout.alignment: Qt.AlignVCenter
    }
  }

}
