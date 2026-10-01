// Liquid Glass uses installed SF Symbols; other styles use Material Symbols.
import QtQuick
import "../../config"
import "../../config/SfSymbols.js" as SfSymbols

Item {
  id: root

  property string iconLabel: ""
  property string iconFont: Config.iconFont
  property bool iconVariableAxes: true
  property color iconColor: Colors.fgSurface
  property real iconSize: Config.iconSize
  property real iconOpacity: 1.0
  property bool filled: false

  readonly property string sfGlyph: Config.liquidGlassTheme
    ? SfSymbols.glyph(root.iconLabel, root.filled) : ""
  readonly property bool usesSfSymbol: root.sfGlyph !== ""
  readonly property real iconBoxSize: Math.max(1, Math.min(
    root.iconSize,
    root.width > 0 ? root.width : root.iconSize,
    root.height > 0 ? root.height : root.iconSize
  ))

  implicitWidth: root.iconSize
  implicitHeight: root.iconSize


  Text {
    anchors.fill: parent
    text: root.usesSfSymbol ? root.sfGlyph : root.iconLabel
    textFormat: Text.PlainText
    color: root.iconColor
    opacity: root.iconOpacity
    font.family: root.usesSfSymbol ? Config.sfSymbolsFont : root.iconFont
    // SF's medium-scale glyphs occupy roughly one em, unlike Material's box.
    font.pixelSize: root.usesSfSymbol ? root.iconBoxSize * 0.8 : root.iconSize
    font.weight: Font.Normal
    font.variableAxes: !root.usesSfSymbol && root.iconVariableAxes
      ? Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
      : ({})
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
