import QtQuick
import QtQuick.Controls
import "../../../config"
import "."
import "../../primitives"

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
  property bool horizontalContent: true
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  property bool expressiveSelectedShape: false
  readonly property bool segmented: root.grouped && root.groupPosition !== "single"
  readonly property bool textVariant: root.variant === "text" || root.variant === "quiet"
  readonly property bool filled: root.selected || root.variant === "filled"
  readonly property string renderedIconLabel: root.segmented && root.selected && root.checkable
    ? "check"
    : root.iconLabel
  property real iconSize: Config.iconSize + 4
  property real contentSpacing: Config.spacingMedium
  // Button content always uses the paired role of its container. This keeps
  // filled, tonal, segmented, and text/outlined variants readable when a
  // palette changes its accent tones.
  property color iconColor: root.segmented
    ? (root.selected ? Colors.fgSecondaryContainer : Colors.fgSurfaceVariant)
    : (root.filled
      ? Colors.fgPrimary
      : (root.variant === "tonal" ? Colors.fgSecondaryContainer : Colors.primary))
  property real radius: theme.controlRadius
  property color color: {
    var overlay = mouseArea.pressed ? Colors.pressOverlay
      : (mouseArea.containsMouse ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.segmented
      ? (root.selected ? Colors.secondaryContainer : Colors.surfaceContainerLow)
      : (root.filled
        ? Colors.primary
        : (root.textVariant || root.variant === "outlined"
          ? "transparent"
          : (root.variant === "elevated" ? Colors.surfaceContainerLow : Colors.secondaryContainer)))
    return Qt.tint(base, overlay)
  }
  property color borderColor: root.segmented || (root.variant === "outlined" && !root.filled)
    ? theme.outline
    : "transparent"
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
    : (root.selected ? (root.grouped ? "Selected option" : "Selected")
      : (root.grouped ? "Option" : ""))

  ExpressiveShape {
    id: selectedShape
    anchors.centerIn: parent
    width: parent.width + 8
    height: parent.height + 8
    visible: root.expressiveSelectedShape && Config.expressiveMotion
    opacity: root.selected ? 0.68 : 0.0
    fillColor: Colors.primaryContainer
    shape: "clover"
    targetMorphProgress: root.selected ? 1.0 : 0.0
    z: -2

    Behavior on opacity {
      NumberAnimation { duration: Config.motionShort }
    }
  }

  Rectangle {
    id: elevationShadow
    x: 0
    y: 2
    width: parent.width
    height: parent.height
    radius: root.radius
    color: Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 0.18)
    visible: root.variant === "elevated" && !root.filled && root.enabled
    z: -1
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    topLeftRadius: root.segmented && root.groupPosition !== "first" ? 0 : root.radius
    topRightRadius: root.segmented && root.groupPosition !== "last" ? 0 : root.radius
    bottomLeftRadius: root.segmented && root.groupPosition !== "first" ? 0 : root.radius
    bottomRightRadius: root.segmented && root.groupPosition !== "last" ? 0 : root.radius
    color: root.color
    border.color: root.borderColor
    border.width: root.segmented ? 0 : root.borderWidth
  }

  // Segmented buttons share one rounded outline. The first segment draws the
  // rounded leading edge, middle/last segments draw one leading divider, and
  // the last segment draws the rounded trailing edge.
  Canvas {
    id: segmentedOutline
    anchors.fill: parent
    visible: root.segmented
    antialiasing: true

    onPaint: {
      var context = getContext("2d")
      context.reset()
      context.strokeStyle = root.borderColor
      context.lineWidth = Math.max(1, root.borderWidth)
      context.lineCap = "butt"
      context.lineJoin = "round"

      var inset = context.lineWidth / 2
      var left = inset
      var top = inset
      var right = width - inset
      var bottom = height - inset
      var radius = Math.min(root.radius, (bottom - top) / 2, (right - left) / 2)

      context.beginPath()
      if (root.groupPosition === "first") {
        context.moveTo(right, top)
        context.lineTo(left + radius, top)
        context.arcTo(left, top, left, top + radius, radius)
        context.lineTo(left, bottom - radius)
        context.arcTo(left, bottom, left + radius, bottom, radius)
        context.lineTo(right, bottom)
      } else if (root.groupPosition === "last") {
        context.moveTo(left, top)
        context.lineTo(right - radius, top)
        context.arcTo(right, top, right, top + radius, radius)
        context.lineTo(right, bottom - radius)
        context.arcTo(right, bottom, right - radius, bottom, radius)
        context.lineTo(left, bottom)
        context.moveTo(left, top)
        context.lineTo(left, bottom)
      } else {
        context.moveTo(left, top)
        context.lineTo(right, top)
        context.moveTo(left, bottom)
        context.lineTo(right, bottom)
        context.moveTo(left, top)
        context.lineTo(left, bottom)
      }
      context.stroke()
    }

    Connections {
      target: root
      function onBorderColorChanged() { segmentedOutline.requestPaint() }
      function onBorderWidthChanged() { segmentedOutline.requestPaint() }
      function onGroupPositionChanged() { segmentedOutline.requestPaint() }
      function onRadiusChanged() { segmentedOutline.requestPaint() }
      function onSegmentedChanged() { segmentedOutline.requestPaint() }
    }
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

  Row {
    id: horizontalContentRow
    visible: root.horizontalContent
      && root.labelText !== ""
      && (root.iconLabel !== "" || root.segmented)
    anchors.centerIn: parent
    width: Math.min(implicitWidth, Math.max(0, root.width - Config.spacingMedium * 2))
    spacing: Math.min(root.contentSpacing, Config.spacingSmall)

    Text {
      id: horizontalIconText
      text: root.renderedIconLabel
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
      font.variableAxes: Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      width: Math.min(implicitWidth, Math.max(0,
        root.width - horizontalIconText.implicitWidth
          - horizontalContentRow.spacing - Config.spacingMedium * 2))
      text: root.labelText
      color: root.iconColor
      font.family: theme.fontFamily
      font.pixelSize: Config.typeLabelMediumSize
      font.weight: Config.typeMediumWeight
      font.letterSpacing: Config.typeLabelTracking
      lineHeight: Config.typeLabelMediumLineHeight
      lineHeightMode: Text.FixedHeight
      elide: Text.ElideRight
      maximumLineCount: 1
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Column {
    id: verticalContentColumn
    visible: !horizontalContentRow.visible
    anchors.centerIn: parent
    spacing: root.labelText !== "" ? root.contentSpacing : 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.renderedIconLabel
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
      font.variableAxes: Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
    }

    Text {
      visible: root.labelText !== ""
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      color: root.iconColor
      font.family: theme.fontFamily
      font.pixelSize: Config.typeLabelMediumSize
      font.weight: Config.typeMediumWeight
      font.letterSpacing: Config.typeLabelTracking
      lineHeight: Config.typeLabelMediumLineHeight
      lineHeightMode: Text.FixedHeight
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
