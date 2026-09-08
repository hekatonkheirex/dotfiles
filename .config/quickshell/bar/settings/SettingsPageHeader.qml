import QtQuick
import QtQuick.Layouts
import "../../config"

ColumnLayout {
  id: pageHeader

  property string pageTitle: ""
  property string subtitle: ""

  Layout.fillWidth: true
  spacing: Config.spacingCompact

  Text {
    text: pageHeader.pageTitle
    color: Colors.fgSurface
    font.family: Config.displayFontFamily
    font.pixelSize: Config.typeHeadlineSmallSize
    font.weight: Config.themeFontWeight
    font.letterSpacing: Config.typeHeadlineTracking
    lineHeight: Config.typeHeadlineSmallLineHeight
    lineHeightMode: Text.FixedHeight
  }

  Text {
    Layout.fillWidth: true
    visible: pageHeader.subtitle !== ""
    text: pageHeader.subtitle
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.typeBodyMediumSize
    font.letterSpacing: Config.typeBodyTracking
    lineHeight: Config.typeBodyMediumLineHeight
    lineHeightMode: Text.FixedHeight
    wrapMode: Text.WordWrap
  }
}
