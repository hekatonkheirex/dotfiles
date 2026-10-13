import QtQuick
import "../../config"

Card {
  id: root

  implicitHeight: col.implicitHeight + Config.spacingLarge * 2

  Column {
    id: col
    anchors.centerIn: parent
    spacing: 4

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: WeatherService.desc !== "" ? WeatherService.desc : WeatherService.statusMessage
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: WeatherService.temp
      color: Colors.tertiary
      font.family: Config.fontFamily
      font.pixelSize: 28
      font.weight: Font.Medium
    }
  }
}
