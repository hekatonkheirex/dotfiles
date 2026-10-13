import QtQuick
import QtQuick.Layouts
import "../../config"

Text {
  Layout.fillWidth: true
  Layout.topMargin: Config.spacingSmall
  Layout.bottomMargin: Config.spacingCompact
  color: Colors.primary
  font.family: Config.fontFamily
  font.pixelSize: Config.typeTitleMediumSize
  font.weight: Config.typeMediumWeight
  font.letterSpacing: Config.typeTitleTracking
  font.capitalization: Font.MixedCase
  wrapMode: Text.WordWrap
}
