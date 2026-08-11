import QtQuick
import QtQuick.Layouts
import Quickshell
import "CalendarLogic.js" as CalendarLogic
import "primitives"
import "../config"

PopupBase {
  id: root

  implicitHeight: Math.min(contentBody.implicitHeight + 24, 450)
  bottomMarginPad: 5

  property date currentDate: new Date()
  property date displayMonth: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)

  readonly property real cellWidth: ((Config.popupWidth) - (Config.popupPadding) * 2 - 6 * 4) / 7
  readonly property bool weekStartsMonday: Settings.calendarWeekStartsMonday
  readonly property var weekDays: CalendarLogic.weekDays(root.weekStartsMonday)
  readonly property var monthNames: CalendarLogic.monthNames

  function daysInMonth(d) { return CalendarLogic.daysInMonth(d) }
  function monthStartDay(d) { return CalendarLogic.monthStartDay(d) }
  function isToday(dayNum) {
    return CalendarLogic.isToday(dayNum, root.displayMonth, root.currentDate)
  }
  function buildDayModel(date) { return CalendarLogic.buildDayModel(date, root.weekStartsMonday) }

  property var dayModel: CalendarLogic.buildDayModel(root.displayMonth, root.weekStartsMonday)

  Column {
    id: contentBody
    anchors {
      fill: parent
      margins: 12
    }
    spacing: 12

        Row {
          width: parent.width
          spacing: 8

          Text {
            text: root.monthNames[root.displayMonth.getMonth()] + " " + root.displayMonth.getFullYear()
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 18
            font.weight: Font.Bold
          }

          Item { width: 1; height: 1; Layout.fillWidth: true }

          Row {
            spacing: 4

            Repeater {
              model: ["chevron_left", "chevron_right"]
              IconButton {
                iconLabel: modelData
                size: 32
                iconSize: 18
                accessibleName: index === 0 ? "Previous month" : "Next month"
                tooltipText: accessibleName
                onClicked: {
                  var m = new Date(root.displayMonth)
                  m.setMonth(m.getMonth() + (index === 0 ? -1 : 1))
                  root.displayMonth = m
                }
              }
            }
          }
        }

        PopupDivider {}

        Row {
          spacing: 4
          Repeater {
            model: root.weekDays
            Text {
              text: modelData
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: 14
              font.weight: Font.Medium
              width: root.cellWidth
              height: 28
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }
        }

        Item {
          width: parent.width
          height: root.dayModel.length > 0 ? (Math.ceil(root.dayModel.length / 7) * 36) : 0

          Repeater {
            model: root.dayModel

            Rectangle {
              property int dayNum: modelData
              visible: dayNum > 0
              x: (index % 7) * (root.cellWidth + 4)
              y: Math.floor(index / 7) * 36
              width: root.cellWidth
              height: 32
              radius: height / 2
              color: root.isToday(dayNum) ? (Colors.primary) : "transparent"

              Text {
                anchors.centerIn: parent
                text: dayNum > 0 ? dayNum.toString() : ""
                color: root.isToday(dayNum)
                  ? (Colors.fgPrimary)
                  : (Colors.fgSurface)
                font.family: Config.fontFamily
                font.pixelSize: 14
              }
            }
          }
        }
      }
}
