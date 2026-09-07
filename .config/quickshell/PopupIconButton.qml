import QtQuick
import QtQuick.Controls

import "."

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool destructive: false
    property color activeColor: Theme.accent
    property color activeForeground: Theme.onAccent
    property string accessibleDescription: ""

    signal activated()

    implicitWidth: Theme.iconButtonSize
    implicitHeight: Theme.iconButtonSize
    opacity: root.enabled ? 1 : 0.5

    Accessible.name: root.label
    Accessible.description: root.accessibleDescription.length > 0
        ? root.accessibleDescription
        : root.label

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeLarge
        color: root.active || iconMouse.pressed || iconMouse.containsMouse
            ? root.activeColor
            : Theme.surfaceContainerHigh
    }

    ToolTip {
        id: iconToolTip

        visible: iconMouse.containsMouse
        text: root.label
        padding: Theme.space8

        contentItem: Text {
            text: iconToolTip.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSmallSize
        }

        background: Rectangle {
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: Theme.outlineVariant
            radius: Theme.shapeSmall
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active || iconMouse.pressed || iconMouse.containsMouse
            ? root.activeForeground
            : (root.destructive ? Theme.danger : Theme.text)
        font.family: "Material Symbols Rounded"
        font.pixelSize: Theme.iconButtonIconSize
        font.weight: Font.Medium
    }

    MouseArea {
        id: iconMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
