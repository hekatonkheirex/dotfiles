import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  implicitHeight: Math.min(contentBody.implicitHeight + 24, 450)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48

  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight - 5))

  property date currentDate: new Date()
  property date displayMonth: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)

  readonly property real cellWidth: ((config ? config.popupWidth : 340) - (config ? config.popupPadding : 16) * 2 - 6 * 4) / 7
  readonly property var weekDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  function daysInMonth(d) {
    return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
  }

  function monthStartDay(d) {
    return new Date(d.getFullYear(), d.getMonth(), 1).getDay()
  }

  function isToday(dayNum) {
    return dayNum === root.currentDate.getDate()
      && root.displayMonth.getMonth() === root.currentDate.getMonth()
      && root.displayMonth.getFullYear() === root.currentDate.getFullYear()
  }

  function buildDayModel(date) {
    if (!date || isNaN(date.getTime())) return []
    var list = []
    var startDay = root.monthStartDay(date)
    var days = root.daysInMonth(date)
    for (var i = 0; i < startDay; i++) list.push(-1)
    for (var d = 1; d <= days; d++) list.push(d)
    while (list.length % 7 !== 0) list.push(-1)
    return list
  }

  property var dayModel: root.buildDayModel(root.displayMonth)

  onVisibleChanged: {
    if (visible) {
      entryAnimation.start()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      config: root.config
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      border.width: 1
      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

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
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: 18
            font.weight: Font.Bold
          }

          Item { width: 1; height: 1; Layout.fillWidth: true }

          Row {
            spacing: 4

            Repeater {
              model: ["chevron_left", "chevron_right"]
              Rectangle {
                width: 32
                height: 32
                radius: 16
                color: navArea.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent"
                Behavior on color {
                  ColorAnimation { duration: config ? config.animationDuration : 150 }
                }
                Text {
                  anchors.centerIn: parent
                  text: modelData
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                  font.family: config ? config.iconFont : "Material Symbols Outlined"
                  font.pixelSize: 18
                }
                MouseArea {
                  id: navArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    var m = new Date(root.displayMonth)
                    m.setMonth(m.getMonth() + (index === 0 ? -1 : 1))
                    root.displayMonth = m
                  }
                }
              }
            }
          }
        }

        Row {
          spacing: 4
          Repeater {
            model: root.weekDays
            Text {
              text: modelData
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              font.family: config ? config.fontFamily : "Google Sans Flex"
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
              color: root.isToday(dayNum) ? (colors_ ? colors_.primary : "#4F378B") : "transparent"

              Text {
                anchors.centerIn: parent
                text: dayNum > 0 ? dayNum.toString() : ""
                color: root.isToday(dayNum)
                  ? (colors_ ? colors_.fgPrimary : "#FFFFFF")
                  : (colors_ ? colors_.fgSurface : "#FFFFFF")
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 14
              }
            }
          }
        }
      }
    }
  }
}
