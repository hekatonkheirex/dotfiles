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
  // Settings navigation uses grouped tonal rows; regular list items keep
  // their independent selection and focus treatment.
  property bool navigationItem: false
  property bool navigationFocused: false
  property int trailingSpacing: Config.spacingCompact
  readonly property bool materialNavigationItem: root.navigationItem
  readonly property bool materialStatusItem: root.statusActive
    && !root.selected
    && !root.navigationItem
  readonly property bool stateHighlighted: root.selected || root.statusActive
  readonly property color selectedContainerColor: root.materialNavigationItem
    ? Colors.secondaryContainer
    : (root.materialStatusItem
      ? Colors.surfaceContainerHighest
      : (Colors.secondaryContainer))
  readonly property color selectedContentColor: root.materialNavigationItem
    ? Colors.fgSecondaryContainer
    : (root.materialStatusItem
      ? Colors.fgSurface
      : (Colors.fgSecondaryContainer))
  property color leadingIconColor: root.stateHighlighted
    ? root.selectedContentColor
    : Colors.fgSurface
  property string accessibleName: ""
  property string accessibleDescription: ""
  // Explicitly associate switch rows with their existing activation path.
  property Item toggleControl: null
  property bool contextMenuEnabled: false
  signal contextMenuRequested(var mouse)
  readonly property bool hovered: itemMouse.containsMouse
  readonly property bool pressed: itemMouse.pressed

  signal clicked(var mouse)

  onClicked: {
    if (root.toggleControl !== null) root.toggleControl.activate()
  }

  implicitHeight: Math.max(Config.controlHitSize, textColumn.implicitHeight + Config.materialRowPadding,
      trailingRow.implicitHeight + Config.materialRowPadding)
  height: implicitHeight
  Layout.minimumHeight: implicitHeight
  radius: root.materialNavigationItem ? height / 2
    : (Config.shapeMedium)
  activeFocusOnTab: root.enabled && (root.toggleControl === null || root.toggleControl.enabled)
  opacity: root.enabled ? 1.0 : 0.38

  Accessible.role: root.toggleControl !== null ? Accessible.CheckBox : Accessible.ListItem
  Accessible.checkable: root.toggleControl !== null
  Accessible.checked: root.toggleControl !== null && root.toggleControl.checked
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
  ColorSpring {
    id: rowEffect
    targetColor: {
      if (root.stateHighlighted) return root.selectedContainerColor
      if (root.materialNavigationItem) {
        if (root.navigationFocused || root.activeFocus) return Qt.tint("transparent", Colors.focusOverlay)
        return itemMouse.containsMouse ? Qt.tint("transparent", Colors.hoverOverlay) : "transparent"
      }
      if (root.navigationFocused) return Qt.tint("transparent", Colors.focusOverlay)
      if (itemMouse.containsMouse) return Qt.tint("transparent", Colors.hoverOverlay)
      return root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    }
  }
  color: rowEffect.color
  border.color: root.materialNavigationItem
    ? "transparent"
    : (root.materialStatusItem || (root.stateHighlighted)
      ? "transparent"
      : (((root.stateHighlighted ? Colors.primary : "transparent"))))
  border.width: root.materialNavigationItem ? 0
    : (root.materialStatusItem || (root.stateHighlighted)
      ? 0 : Config.themeBorderWidth)

  Behavior on color {
    enabled: false
    ColorAnimation { duration: Config.animationDuration }
  }

  // Keyboard focus ring: the 8% tint alone is invisible on selected or
  // status rows. Navigation rows keep their own focus treatment.
  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: root.activeFocus && !root.navigationItem ? 2 : 0
    border.color: Colors.primary
    visible: border.width > 0
    z: 5
  }

  // Keep the row hit target below its content so trailing controls can still
  // receive clicks. Non-interactive text falls through to this MouseArea.
  MouseArea {
    id: itemMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: root.contextMenuEnabled ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
    enabled: root.enabled
    cursorShape: root.toggleControl !== null && !root.toggleControl.enabled
      ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.forceActiveFocus()
      if (mouse.button === Qt.RightButton) {
        root.contextMenuRequested(mouse)
        return
      }
      root.clicked(mouse)
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Config.spacingSmall
    anchors.rightMargin: Config.spacingSmall
    spacing: Config.spacingSmall

    Item {
      visible: root.leadingIcon !== "" && root.leadingImageSource === ""
      Layout.preferredWidth: root.materialNavigationItem ? 32 : Math.max(30, Config.iconSize + 6)
      Layout.preferredHeight: Layout.preferredWidth
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        visible: root.materialNavigationItem
        color: root.selected
          ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
          : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.10)
      }

      IconGlyph {
        anchors.centerIn: parent
        iconLabel: root.leadingIcon
        iconColor: root.materialNavigationItem
          ? (root.selected ? Colors.primary : Colors.fgSurfaceVariant)
          : (root.stateHighlighted ? root.selectedContentColor : root.leadingIconColor)
        iconOpacity: root.leadingIconOpacity
        iconSize: root.materialNavigationItem ? 20 : Config.iconSize + 6
        filled: root.stateHighlighted
      }
    }

    Rectangle {
      visible: root.leadingImageSource !== "" || root.leadingFallbackText !== ""
      width: 30
      height: 30
      radius: 15
      color: Colors.surfaceContainerHigh
      Layout.alignment: Qt.AlignVCenter

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
      id: textColumn
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
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
        wrapMode: !root.navigationItem ? Text.Wrap : Text.NoWrap
        elide: !root.navigationItem ? Text.ElideNone : Text.ElideRight
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
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
      }
    }

    Row {
      id: trailingRow
      spacing: root.trailingSpacing
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
