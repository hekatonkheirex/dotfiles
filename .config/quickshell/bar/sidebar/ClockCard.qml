import QtQuick
import "../../config"
import "../../config/ClockTiming.js" as ClockTiming
import "../../config/Weekdays.js" as Weekdays

Card {
  id: root

  property date now: new Date()

  implicitHeight: col.implicitHeight + Config.spacingLarge * 2

  Timer {
    interval: ClockTiming.nextInterval(root.now, false)
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  Column {
    id: col
    anchors.centerIn: parent
    spacing: Config.spacingMedium

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.spacingMedium

      Text {
        text: Qt.formatTime(root.now, Settings.clock24h ? "HH" : "h")
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: 56
        font.weight: Font.Medium
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
          model: [Colors.secondary, Colors.tertiary, Colors.primary]
          Rectangle { width: 8; height: 8; radius: 2; color: modelData }
        }
      }

      Text {
        text: Qt.formatTime(root.now, "mm")
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: 56
        font.weight: Font.Medium
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.spacingSmall

      Repeater {
        model: Weekdays.weekRow(root.now)

        Item {
          width: 30
          height: 30

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.secondary
            visible: modelData.isToday
          }
          Text {
            anchors.centerIn: parent
            text: modelData.letter
            color: modelData.isToday ? Colors.fgSecondary : Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Font.Medium
          }
        }
      }
    }
  }
}
