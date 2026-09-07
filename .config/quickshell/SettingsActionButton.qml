import QtQuick

import "."

Item {
    id: root

    property string text: ""
    property bool emphasized: false
    property bool enabled: true

    signal clicked()

    implicitWidth: actionLabel.implicitWidth + 32
    implicitHeight: Theme.controlHeight
    opacity: root.enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: root.emphasized
            ? (actionMouse.containsMouse ? Theme.accentAlt : Theme.accent)
            : (actionMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
        border.width: root.emphasized ? 0 : 1
        border.color: Theme.outlineVariant

        Text {
            id: actionLabel
            anchors.centerIn: parent
            text: root.text
            color: root.emphasized ? Theme.onAccent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelMediumSize
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: actionMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
