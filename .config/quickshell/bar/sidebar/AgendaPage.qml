import QtQuick
import Quickshell
import "../../config"
import "../CalendarLogic.js" as CalendarLogic

// Page 1: her task ring (no task source, so 0), month and year steppers, the
// month grid and the empty task list.
Item {
  id: root
  property bool active: false
  property date today: new Date()
  property bool weekStartsMonday: false
  // Months away from today's month; the arrows move it, closing resets it.
  property int monthOffset: 0
  readonly property date shownMonth: new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1)
  readonly property var cells: CalendarLogic.buildMonthGrid(root.shownMonth, root.weekStartsMonday)
  readonly property bool todayShown: root.shownMonth.getFullYear() === root.today.getFullYear()
    && root.shownMonth.getMonth() === root.today.getMonth()
  readonly property int todayColumn: root.weekStartsMonday ? (root.today.getDay() + 6) % 7 : root.today.getDay()
  readonly property var letters: root.weekStartsMonday ? ["m", "t", "w", "t", "f", "s", "s"] : ["s", "m", "t", "w", "t", "f", "s"]
  readonly property var weekendColumns: root.weekStartsMonday ? [5, 6] : [0, 6]
  readonly property int tasks: 0

  SystemClock { id: clock; precision: SystemClock.Hours; enabled: root.active }
  Binding { target: root; property: "today"; value: clock.date; when: root.active }
  onActiveChanged: if (!root.active) root.monthOffset = 0

  Column {
    anchors.top: parent.top
    anchors.topMargin: Config.dp(30)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Config.dp(14)

    Row {   // header: task ring, month and year steppers
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.dp(18)

      Item {
        width: Config.dp(64)
        height: width
        Canvas {
          id: ring
          anchors.fill: parent
          property color track: Colors.surfaceContainerHighest
          property color fill: Colors.elenaAccent(2)
          onTrackChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var lw = Config.dp(6)
            ctx.lineWidth = lw
            ctx.strokeStyle = track
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, width / 2 - lw / 2, 0, 2 * Math.PI)
            ctx.stroke()
            if (root.tasks > 0) {   // never today: no task source
              ctx.strokeStyle = fill
              ctx.beginPath()
              ctx.arc(width / 2, height / 2, width / 2 - lw / 2, -Math.PI / 2, 3 * Math.PI / 2)
              ctx.stroke()
            }
          }
        }
        Column {
          anchors.centerIn: parent
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: String(root.tasks)
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(14)
            font.weight: Font.Bold
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "tasks"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(7)
          }
        }
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.dp(2)
        Repeater {
          // [label, months per step]
          model: [[Qt.formatDate(root.shownMonth, "MMMM"), 1], [Qt.formatDate(root.shownMonth, "yyyy"), 12]]
          Row {
            id: stepRow
            required property var modelData
            readonly property int months: modelData[1]
            spacing: Config.dp(6)
            Text {
              width: Config.dp(84)
              anchors.verticalCenter: parent.verticalCenter
              text: modelData[0]
              color: modelData[1] === 1 ? Colors.fgSurface : Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.dp(modelData[1] === 1 ? 14 : 11)
              font.weight: modelData[1] === 1 ? Font.Bold : Font.Normal
            }
            Repeater {
              model: [[-1, ""], [1, ""]]   // up = earlier, down = later
              Text {
                required property var modelData
                property int step: modelData[0]
                anchors.verticalCenter: parent.verticalCenter
                text: modelData[1]
                color: arrow.containsMouse ? Colors.elenaAccent(2) : Colors.fgSurfaceVariant
                font.family: BottomBarFonts.family
                font.pixelSize: Config.dp(12)
                MouseArea {
                  id: arrow
                  anchors.fill: parent
                  anchors.margins: -Config.dp(3)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.monthOffset += parent.step * stepRow.months
                }
              }
            }
          }
        }
      }
    }

    Row {   // weekday letters
      anchors.horizontalCenter: parent.horizontalCenter
      Repeater {
        model: root.letters
        Text {
          required property int index
          required property string modelData
          width: Config.dp(36)
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: index === root.todayColumn ? Colors.elenaAccent(1) : Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
          font.weight: Font.Bold
        }
      }
    }

    Grid {   // six rows of seven days
      anchors.horizontalCenter: parent.horizontalCenter
      columns: 7
      Repeater {
        model: 42
        Item {
          required property int index
          readonly property var cell: root.cells[index]
          readonly property bool isToday: root.todayShown && !cell.other && cell.day === root.today.getDate()
          objectName: isToday ? "todayCell" : ("dayCell" + index)
          width: Config.dp(36)
          height: Config.dp(28)
          Rectangle {
            anchors.centerIn: parent
            width: Config.dp(24)
            height: width
            radius: width / 2
            visible: parent.isToday
            color: Colors.fgSurface
          }
          Text {
            anchors.centerIn: parent
            text: parent.cell.day
            opacity: parent.cell.other ? 0.5 : 1
            color: parent.isToday ? Colors.surface
              : (parent.cell.other ? Colors.outline
              : (root.weekendColumns.indexOf(parent.index % 7) >= 0 ? Colors.elenaAccent(2) : Colors.fgSurface))
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(10)
            font.weight: parent.isToday ? Font.Bold : Font.Normal
          }
        }
      }
    }

    Flickable {   // task list (empty state; ready for a future source)
      objectName: "taskList"
      anchors.horizontalCenter: parent.horizontalCenter
      width: Config.dp(252)
      height: Config.dp(90)
      clip: true
      contentHeight: empty.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: empty
        width: parent.width
        topPadding: Config.dp(14)
        spacing: Config.dp(6)
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: ""
          color: Colors.fgSurfaceVariant
          font.family: BottomBarFonts.family
          font.pixelSize: Config.dp(20)
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "You have no tasks"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
        }
      }
    }
  }
}
