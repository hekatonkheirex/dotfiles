import QtQuick

import "."

Item {
    id: root

    property string title: ""
    property string description: ""
    property string badge: ""
    property bool placeholder: false

    default property alias control: controlHost.data

    implicitWidth: 760
    implicitHeight: Math.max(60, titleBlock.implicitHeight + 20)

    Column {
        id: titleBlock
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: controlHost.left
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space4

        Row {
            spacing: Theme.space8

            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyMediumSize
                font.weight: Font.DemiBold
            }

            Rectangle {
                visible: root.badge.length > 0
                width: badgeLabel.implicitWidth + 10
                height: 18
                radius: Theme.shapeExtraSmall
                color: Theme.accentSurface

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.badge
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSmallSize
                    font.weight: Font.DemiBold
                }
            }
        }

        Text {
            visible: root.description.length > 0
            width: parent.width
            text: root.description
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSmallSize
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: controlHost
        width: 360
        height: parent.height
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        visible: root.placeholder
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 108
        height: 28
        radius: Theme.shapeMedium
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant

        Text {
            anchors.centerIn: parent
            text: "Placeholder"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSmallSize
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.outlineVariant
    }
}
