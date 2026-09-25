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
    text: Config.ghostTheme ? pageHeader.pageTitle.toUpperCase() : pageHeader.pageTitle
    color: Colors.fgSurface
    font.family: Config.displayFontFamily
    font.pixelSize: pageHeader.width < 360 ? Config.typeHeadlineSmallSize
      : (Config.ghostTheme ? Config.typeHeadlineSmallSize + 2
        : (Config.nothingDesign && !Config.nothingEvolution
          ? Config.typeHeadlineMediumSize : Config.typeHeadlineLargeSize))
    font.weight: Config.material3Theme ? Config.typeMediumWeight
      : (Config.ghostTheme ? Config.typeMediumWeight : Config.themeFontWeight)
    font.letterSpacing: Config.ghostTheme ? Config.typeMonoTracking : Config.typeHeadlineTracking
    lineHeight: Config.ghostTheme ? Config.typeHeadlineMediumLineHeight
      : Config.typeHeadlineLargeLineHeight
    lineHeightMode: Text.FixedHeight
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
