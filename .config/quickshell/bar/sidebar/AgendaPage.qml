import QtQuick
import Quickshell
import "../../config"
import "../CalendarLogic.js" as CalendarLogic

// Page 1: ring counting the picked day's Apple Calendar events, month and year
// steppers, the month grid (a click picks a day, a dot marks days with events)
// and that day's event list.
Item {
  id: root
  property bool active: false
  property date today: new Date()
  property bool weekStartsMonday: false
  // Sidebar-level open flag (not this page's `active`): closing the sidebar
  // resets the shown month, switching pages does not.
  property bool sidebarOpen: false
  // Months away from today's month; the arrows move it, closing resets it.
  property int monthOffset: 0
  readonly property date shownMonth: new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1)
  readonly property var cells: CalendarLogic.buildMonthGrid(root.shownMonth, root.weekStartsMonday)
  readonly property bool todayShown: root.shownMonth.getFullYear() === root.today.getFullYear()
    && root.shownMonth.getMonth() === root.today.getMonth()
  readonly property int todayColumn: root.weekStartsMonday ? (root.today.getDay() + 6) % 7 : root.today.getDay()
  readonly property var letters: root.weekStartsMonday ? ["m", "t", "w", "t", "f", "s", "s"] : ["s", "m", "t", "w", "t", "f", "s"]
  readonly property var weekendColumns: root.weekStartsMonday ? [5, 6] : [0, 6]
  // Fed by CalendarService: events are {date, start, end, title, allDay}.
  property var events: []
  property string calendarStatus: "ok"
  property string calendarMessage: ""
  // The day the list shows; empty means today. Closing the sidebar clears it.
  property string pickedKey: ""
  readonly property string todayKey: CalendarLogic.dateKey(root.today)
  readonly property string selectedKey: root.pickedKey !== "" ? root.pickedKey : root.todayKey
  readonly property var dayEvents: CalendarLogic.eventsOn(root.events, root.selectedKey)
  readonly property var eventDays: CalendarLogic.daysWithEvents(root.events)
  readonly property int tasks: root.dayEvents.length
  // Range CalendarService fetches: the 42 cells on show.
  readonly property string rangeStart: CalendarLogic.gridRange(root.cells).start
  readonly property string rangeEnd: CalendarLogic.gridRange(root.cells).end

  SystemClock { id: clock; precision: SystemClock.Hours; enabled: root.active }
  Binding { target: root; property: "today"; value: clock.date; when: root.active }
  onSidebarOpenChanged: if (!root.sidebarOpen) { root.monthOffset = 0; root.pickedKey = "" }

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
          Connections { target: root; function onTasksChanged() { ring.requestPaint() } }
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var lw = Config.dp(6)
            ctx.lineWidth = lw
            ctx.strokeStyle = track
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, width / 2 - lw / 2, 0, 2 * Math.PI)
            ctx.stroke()
            if (root.tasks > 0) {
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
            text: root.tasks === 1 ? "event" : "events"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(7)
          }
        }
      }

      StepArrows { months: 1; onStepped: function(m) { root.monthOffset += m } }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: Config.dp(84)
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(root.shownMonth, "MMMM")
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(14)
          font.weight: Font.Bold
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(root.shownMonth, "yyyy")
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(11)
        }
      }
      StepArrows { months: 12; onStepped: function(m) { root.monthOffset += m } }
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
          readonly property bool isPicked: cell.key !== "" && cell.key === root.selectedKey && !isToday
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
          Rectangle {   // picked day (today keeps its filled round)
            anchors.centerIn: parent
            width: Config.dp(24)
            height: width
            radius: width / 2
            visible: parent.isPicked
            color: "transparent"
            border.width: 1
            border.color: Colors.elenaAccent(1)
          }
          Rectangle {   // event dot
            objectName: "eventDot" + parent.index
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.dp(1)
            width: Config.dp(3)
            height: width
            radius: width / 2
            visible: root.eventDays[parent.cell.key] === true
            color: parent.isToday ? Colors.fgSurface : Colors.elenaAccent(2)
          }
          MouseArea {
            anchors.fill: parent
            enabled: parent.cell.key !== ""
            onClicked: root.pickedKey = parent.cell.key
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

    Flickable {   // the picked day's events, or the empty state
      objectName: "taskList"
      anchors.horizontalCenter: parent.horizontalCenter
      width: Config.dp(252)
      height: Config.dp(150)
      clip: true
      contentHeight: list.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: list
        width: parent.width
        spacing: Config.dp(8)
        topPadding: Config.dp(8)
        Repeater {
          model: root.dayEvents
          Row {
            required property int index
            required property var modelData
            objectName: "eventRow" + index
            spacing: Config.dp(10)
            Text {
              width: Config.dp(52)
              objectName: "eventTime" + parent.index
              text: parent.modelData.allDay ? "all day" : parent.modelData.start
              color: parent.modelData.color ? parent.modelData.color : Colors.elenaAccent(1)
              font.family: Config.fontFamily
              font.pixelSize: Config.dp(10)
              font.weight: Font.Bold
            }
            Text {
              width: list.width - Config.dp(62)
              text: parent.modelData.title
              elide: Text.ElideRight
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.dp(10)
            }
          }
        }
        Column {   // empty, unlinked and error states
          visible: root.tasks === 0
          width: parent.width
          topPadding: Config.dp(6)
          spacing: Config.dp(6)
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: Colors.fgSurfaceVariant
            font.family: BottomBarFonts.family
            font.pixelSize: Config.dp(20)
          }
          Text {
            objectName: "emptyText"
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.calendarStatus === "unconfigured" ? "No calendar linked"
              : root.calendarStatus === "error" ? "Calendar unavailable"
              : "You have no events"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(10)
          }
          Text {
            visible: root.calendarStatus === "unconfigured" || root.calendarStatus === "error"
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.calendarMessage
            color: Colors.outline
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(8)
          }
        }
      }
    }
  }
}
