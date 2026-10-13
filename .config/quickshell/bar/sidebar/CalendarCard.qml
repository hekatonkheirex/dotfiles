import QtQuick
import QtQuick.Layouts
import "../../config"
import "../primitives"
import "../CalendarLogic.js" as Calendar

Card {
  id: root
  property bool active: false
  property date today: new Date()
  property date displayMonth: new Date(today.getFullYear(), today.getMonth(), 1)
  readonly property var days: Calendar.buildDayModel(displayMonth, Settings.calendarWeekStartsMonday)
  implicitHeight: body.implicitHeight + Config.spacingMedium * 2

  function moveMonth(delta) {
    displayMonth = new Date(displayMonth.getFullYear(), displayMonth.getMonth() + delta, 1)
  }
  onActiveChanged: if (active) today = new Date()
  Timer {
    interval: 60000
    repeat: true
    running: root.active
    onTriggered: root.today = new Date()
  }

  ColumnLayout {
    id: body
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Config.spacingMedium }
    spacing: Config.spacingSmall
    RowLayout {
      Layout.fillWidth: true
      Text {
        Layout.fillWidth: true
        text: Calendar.monthNames[root.displayMonth.getMonth()] + " " + root.displayMonth.getFullYear()
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeTitleMediumSize
        font.weight: Config.typeStrongWeight
        elide: Text.ElideRight
      }
      IconButton {
        iconLabel: "chevron_left"
        size: 32
        iconSize: 20
        accessibleName: "Previous month"
        onClicked: root.moveMonth(-1)
      }
      IconButton {
        iconLabel: "chevron_right"
        size: 32
        iconSize: 20
        accessibleName: "Next month"
        onClicked: root.moveMonth(1)
      }
    }
    GridLayout {
      Layout.fillWidth: true
      columns: 7
      columnSpacing: 0
      rowSpacing: Config.spacingCompact
      Repeater {
        model: Calendar.weekDays(Settings.calendarWeekStartsMonday)
        Text {
          required property string modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 24
          text: modelData.substring(0, 1)
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelLargeSize
          Accessible.name: modelData
        }
      }
      Repeater {
        model: root.days
        Rectangle {
          required property int modelData
          readonly property bool isToday: Calendar.isToday(modelData, root.displayMonth, root.today)
          Layout.fillWidth: true
          Layout.preferredHeight: 28
          radius: height / 2
          color: modelData > 0 && isToday ? Colors.secondary : "transparent"
          Text {
            anchors.centerIn: parent
            text: parent.modelData > 0 ? parent.modelData : ""
            color: parent.isToday ? Colors.fgSecondary : Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelLargeSize
          }
          Accessible.role: Accessible.StaticText
          Accessible.name: modelData > 0 ? Qt.formatDate(new Date(root.displayMonth.getFullYear(), root.displayMonth.getMonth(), modelData), "dddd d MMMM yyyy") + (isToday ? ", today" : "") : ""
          Accessible.ignored: modelData < 1
        }
      }
    }
  }
}
