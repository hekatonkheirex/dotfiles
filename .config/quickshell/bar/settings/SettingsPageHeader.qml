import QtQuick
import QtQuick.Layouts
import "../../config"

ColumnLayout {
  id: pageHeader

  property string pageTitle: ""
  property string subtitle: ""

  Layout.fillWidth: true
  spacing: Config.spacingSmall
  Layout.bottomMargin: Config.spacingSmall

  Text {
    Layout.fillWidth: true
    text: pageHeader.pageTitle
    color: Colors.fgSurface
    font.family: Config.displayFontFamily
    font.pixelSize: pageHeader.width < 360 ? Config.typeHeadlineSmallSize
      : Config.typeHeadlineLargeSize
    font.weight: Config.typeMediumWeight
    font.letterSpacing: Config.typeHeadlineTracking
    lineHeight: Config.typeHeadlineLargeLineHeight
    lineHeightMode: Text.FixedHeight
    // NType 82 Headline draws a very narrow space, so "Display & Input" reads
    // "Display&Input".
    font.wordSpacing: 0
    wrapMode: Text.WordWrap
  }

  Text {
    Layout.fillWidth: true
    visible: pageHeader.subtitle !== ""
    text: pageHeader.subtitle
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.typeBodyLargeSize
    font.letterSpacing: Config.typeBodyTracking
    lineHeight: Config.typeBodyLargeLineHeight
    lineHeightMode: Text.FixedHeight
    wrapMode: Text.WordWrap
  }
}
