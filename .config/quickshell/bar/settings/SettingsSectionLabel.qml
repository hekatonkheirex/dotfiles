import QtQuick
import QtQuick.Layouts
import "../../config"

Text {
  Layout.fillWidth: true
  Layout.topMargin: Config.spacingSmall
  Layout.bottomMargin: Config.spacingCompact
  color: Config.material3Theme ? Colors.primary : Colors.fgSurface
  font.family: Config.fontFamily
  font.pixelSize: Config.typeTitleMediumSize
  font.weight: Config.typeMediumWeight
  font.letterSpacing: Config.ghostTheme ? Config.typeMonoTracking : Config.typeTitleTracking
  font.capitalization: Config.ghostTheme ? Font.AllUppercase : Font.MixedCase
  wrapMode: Text.WordWrap
}
