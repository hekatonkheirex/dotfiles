import QtQuick

import "."

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool destructive: false
    property bool compact: false
    property color activeColor: Theme.accent

    signal activated()

    implicitHeight: Theme.controlHeight
    implicitWidth: content.implicitWidth + (root.compact ? 18 : 24)

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: root.destructive
            ? (mouseArea.pressed || mouseArea.containsMouse ? Theme.dangerSurface : "transparent")
            : (root.active
                ? Theme.accentSurface
                : (mouseArea.pressed
                    ? Theme.surfaceContainerHighest
                    : (mouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent")))
        border.width: root.active || root.destructive && mouseArea.containsMouse ? 1 : 0
        border.color: root.destructive ? Theme.danger : Theme.outlineVariant
    }

    Row {
        id: content
        anchors.centerIn: parent
        height: parent.height
        spacing: Theme.space4

        Text {
            visible: root.icon.length > 0
            height: parent.height
            text: root.icon
            color: root.destructive ? Theme.danger : (root.active ? root.activeColor : Theme.text)
            font.family: "Material Symbols Rounded"
            font.pixelSize: root.compact ? 18 : 19
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: root.label.length > 0
            height: parent.height
            text: root.label
            color: root.destructive
                ? Theme.danger
                : (root.active ? root.activeColor : Theme.text)
            font.family: Theme.fontFamily
            font.pixelSize: root.compact ? Theme.labelSmallSize : Theme.labelMediumSize
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
