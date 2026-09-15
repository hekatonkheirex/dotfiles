// Theme-aware icon primitive. Liquid Glass uses the active symbolic icon
// theme, while the other styles retain their Material Symbols text path.
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import "../../config"

Item {
  id: root

  property string iconLabel: ""
  property string iconFont: Config.iconFont
  property bool iconVariableAxes: true
  property color iconColor: Colors.fgSurface
  property real iconSize: Config.iconSize
  property real iconOpacity: 1.0
  property bool filled: false

  readonly property bool liquidGlass: Config.liquidGlassTheme
  readonly property string symbolName: Config.liquidGlassIconName(root.iconLabel)
  readonly property string symbolSource: root.liquidGlass
    ? Quickshell.iconPath(root.symbolName, "application-x-executable-symbolic")
    : ""
  readonly property real symbolScale: root.liquidGlass
    ? Config.liquidGlassIconScale(root.iconLabel)
    : 1.0
  readonly property real iconBoxSize: Math.max(1, Math.min(
    root.width > 0 ? root.width : root.iconSize,
    root.height > 0 ? root.height : root.iconSize
  ))

  implicitWidth: root.iconSize
  implicitHeight: root.iconSize

  Item {
    id: symbolFrame
    anchors.centerIn: parent
    width: root.iconBoxSize * root.symbolScale
    height: width

    IconImage {
      id: symbolImage
      anchors.fill: parent
      implicitSize: symbolFrame.width
      source: root.symbolSource
      // ColorOverlay renders this item as its source. Keep the source hidden
      // so the un-tinted SVG is not composited a second time underneath it.
      visible: false
    }

    // MacTahoe's symbolic SVGs are intentionally monochrome. Recolor the
    // rendered asset so semantic states (error, warning, selected) still use
    // the same palette roles as the rest of the shell.
    ColorOverlay {
      anchors.fill: symbolImage
      source: symbolImage
      color: root.iconColor
      opacity: root.iconOpacity
      visible: root.liquidGlass && root.symbolSource !== ""
    }
  }

  Text {
    anchors.fill: parent
    visible: !root.liquidGlass
    text: root.iconLabel
    color: root.iconColor
    opacity: root.iconOpacity
    font.family: root.iconFont
    font.pixelSize: root.iconSize
    font.variableAxes: root.iconVariableAxes
      ? Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
      : ({})
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
