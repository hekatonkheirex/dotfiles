import QtQuick
import QtQuick.Layouts

import Quickshell

import "."

PopupPanel {
    id: root

    property var clock
    property int monthOffset: 0
    panelNamespace: "quickshell-hyprland-popup-calendar"
    property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    property var visibleMonth: {
        var current = root.clock ? root.clock.date : new Date();
        return new Date(current.getFullYear(), current.getMonth() + root.monthOffset, 1);
    }
    property int firstDay: (new Date(
        root.visibleMonth.getFullYear(), root.visibleMonth.getMonth(), 1
    ).getDay() + 6) % 7
    property int daysInMonth: new Date(
        root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() + 1, 0
    ).getDate()

    implicitWidth: 304
    implicitHeight: 348
    visible: false

    onVisibleChanged: if (!visible) root.monthOffset = 0

    PopupMotion {
        revealed: root.visible

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            anchors.topMargin: 0
            radius: Theme.shapeExtraLarge
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Theme.outlineVariant

        Row {
            id: monthHeader
            x: 16
            y: 16
            width: parent.width - 32
            height: 30
            spacing: 6

            Rectangle {
                width: 30
                height: 30
                radius: Theme.shapeMedium
                color: previousMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Theme.text
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }

                MouseArea {
                    id: previousMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset -= 1
                }
            }

            Text {
                width: monthHeader.width - 72
                height: 30
                text: Qt.formatDateTime(root.visibleMonth, "MMMM yyyy")
                color: Theme.text
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 30
                height: 30
                radius: Theme.shapeMedium
                color: nextMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: Theme.text
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset += 1
                }
            }
        }

        GridLayout {
            id: calendarGrid
            x: 16
            y: 64
            width: parent.width - 32
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: root.dayNames

                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    text: modelData
                    color: Theme.muted
                    font.family: "Roboto Flex"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Repeater {
                model: 42

                delegate: Rectangle {
                    required property int index

                    property int dayOffset: index - root.firstDay
                    property bool inCurrentMonth: dayOffset >= 0 && dayOffset < root.daysInMonth
                    property int dayNumber: inCurrentMonth
                        ? dayOffset + 1
                        : (dayOffset < 0
                            ? new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth(), 0).getDate() + dayOffset + 1
                            : dayOffset - root.daysInMonth + 1)
                    property bool isToday: {
                        var now = root.clock ? root.clock.date : new Date();
                        return inCurrentMonth
                            && dayNumber === now.getDate()
                            && root.visibleMonth.getMonth() === now.getMonth()
                            && root.visibleMonth.getFullYear() === now.getFullYear();
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: isToday ? Theme.accent : (inCurrentMonth ? Theme.surfaceContainerHigh : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: dayNumber
                        color: parent.isToday ? Theme.onAccent : (parent.inCurrentMonth ? Theme.text : Theme.muted)
                        opacity: parent.inCurrentMonth ? 1 : 0.55
                        font.family: "Roboto Flex"
                        font.pixelSize: 12
                        font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                text: "Click the clock to close"
                color: Theme.muted
                font.family: "Roboto Flex"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
