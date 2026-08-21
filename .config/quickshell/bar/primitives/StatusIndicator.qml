// Shared bar-indicator chrome: icon + optional value label inside a hover/
// press/active tinted pill. Audio, battery, brightness, Wi-Fi, Bluetooth,
// menu, notification, and launcher indicators all repeated this Rectangle +
// Text + MouseArea block verbatim before this primitive existed.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config"

Item {
  id: root

  property bool horizontal: false
  property bool inlineContent: false
  property bool integrated: false
  property bool active: false
  property string iconLabel: ""
  property real iconOpacity: 1.0
  property string labelText: ""
  property real labelOpacity: 1.0
  property color accentColor: Config.nothingDesign ? Colors.fgSurface : Colors.primary
  property color iconColor: root.accentColor
  property color labelColor: root.accentColor
  property color inactiveBg: Colors.surfaceContainerHigh
  // Indicators stay quiet at rest and reveal their outline on hover/focus;
  // active state is conveyed by the content color and owning popup surface.
  property bool borderOnHoverOnly: true
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  property string badgeText: ""
  property color badgeColor: Colors.error
  property color badgeTextColor: Colors.fgError

  // Nothing's dot-matrix numeral font is reserved for pure numeric readouts
  // (battery/brightness/volume %), not textual states like "Muted" or
  // workspace names.
  readonly property bool numericLabel: /^-?\d+%?$/.test(root.labelText)

  // Icon-only indicators do not need the full widget slot in the vertical
  // bar. Keep their hit target tied to the icon size so they do not leave
  // larger visual gaps than indicators that also show a value label. Icon +
  // label indicators size to their actual stacked content instead of a flat
  // widget size, so the rounded pill has room for both without clipping.
  readonly property int verticalLayoutHeight: root.labelText !== ""
    ? Math.max(Config.widgetSize, Config.iconSize + Config.spacingSmall + Config.labelSmallSize + Config.spacingMedium * 2)
    : Math.min(Config.widgetSize, Config.iconSize + Config.spacingSmall)
  // Inline pills need breathing room around the icon/label pair. The
  // wrapper uses this value for its width, so the text does not end up under
  // the pill border when a value such as "100%" is displayed.
  readonly property real horizontalContentWidth: contentLayout.implicitWidth
    + (root.inlineContent ? Config.spacingSmall * 2 : 0)

  signal clicked(var mouse)
  signal wheel(var wheel)

  Layout.preferredWidth: Config.widgetSize
  Layout.preferredHeight: Config.widgetSize
  activeFocusOnTab: root.enabled
  opacity: root.enabled ? 1.0 : 0.38

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName !== ""
    ? root.accessibleName
    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : "Status indicator"))
  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.active ? "Active" : "")
  Accessible.focusable: root.activeFocusOnTab
  Accessible.focused: root.activeFocus

  Rectangle {
    id: shadow
    x: bgOverlay.x + Config.themeShadowOffset
    y: bgOverlay.y + Config.themeShadowOffset
    width: bgOverlay.width
    height: bgOverlay.height
    radius: bgOverlay.radius
    color: Colors.styleShadow
    visible: Config.neoBrutalism && root.enabled && !root.integrated
    z: -1
  }

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.clicked(null)
      event.accepted = true
    }
  }

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: Config.neoBrutalism
      ? Config.shapeMedium
      : (root.horizontal ? height / 2 : width / 2)
    clip: true
    color: {
      var overlay = mouseArea.pressed ? Colors.pressOverlay
        : (mouseArea.containsMouse ? Colors.hoverOverlay
          : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
      var base = root.integrated
        ? "transparent"
        : (root.borderOnHoverOnly
          ? ((Config.neoBrutalism || Config.nothingDesign) ? Colors.styleSurface : "transparent")
          : root.inactiveBg)
      return Qt.tint(base, overlay)
    }
    border.color: {
      if (Config.neoBrutalism) return Colors.styleOutline
      if (Config.nothingDesign) return "transparent"
      if (root.active) return root.activeFocus ? Colors.focusOverlay : "transparent"
      if (root.borderOnHoverOnly && !mouseArea.containsMouse && !root.activeFocus) return "transparent"
      return Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)
    }
    border.width: root.integrated || Config.nothingDesign ? 0 : Config.themeBorderWidth

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration }
    }
  }

  GridLayout {
    id: contentLayout
    anchors.centerIn: parent
    columns: root.inlineContent ? (root.labelText !== "" ? 2 : 1) : 1
    rows: root.inlineContent ? 1 : (root.labelText !== "" ? 2 : 1)
    flow: root.inlineContent ? GridLayout.LeftToRight : GridLayout.TopToBottom
    columnSpacing: root.inlineContent && root.labelText !== ""
      ? Config.spacingCompact
      : 0
    rowSpacing: !root.inlineContent && root.labelText !== ""
      ? Config.spacingSmall
      : 0

    Text {
      id: iconText
      text: root.iconLabel
      opacity: root.iconOpacity
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: Config.iconSize
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      Layout.preferredWidth: Config.iconSize
      Layout.preferredHeight: Config.iconSize
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }

    Text {
      id: labelTextItem
      visible: root.labelText !== ""
      text: root.labelText
      opacity: root.labelOpacity
      color: root.labelColor
      font.family: Config.nothingDesign
        ? (root.numericLabel ? Config.dotFontFamily : Config.monoFontFamily)
        : Config.fontFamily
      font.pixelSize: Config.labelSmallSize
      font.weight: Config.neoBrutalism || Config.nothingDesign ? Config.themeFontWeight : Font.Medium
      font.letterSpacing: Config.nothingDesign ? 0.3 : 0
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      Layout.preferredWidth: implicitWidth
      Layout.maximumWidth: root.inlineContent
        ? implicitWidth
        : Math.max(0, root.width - Config.spacingSmall)
      Layout.preferredHeight: implicitHeight
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }
  }

  Item {
    anchors.fill: parent
    visible: root.badgeText !== ""

    Rectangle {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: 4
      anchors.topMargin: 4
      width: badgeLabel.implicitWidth + 6
      height: 14
      radius: 7
      color: root.badgeColor

      Text {
        id: badgeLabel
        anchors.centerIn: parent
        text: root.badgeText
        color: root.badgeTextColor
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize - 3
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
    onWheel: function(wheelEvent) { root.wheel(wheelEvent) }
  }

}
