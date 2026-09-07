import QtQuick

import "."

PopupPanel {
    id: root

    property var notificationService

    readonly property int notificationCount: root.notificationService
        ? root.notificationService.notificationCount
        : 0
    readonly property int listHeight: root.notificationCount > 0
        ? Math.min(520, root.notificationCount * 156)
        : 62

    panelNamespace: "quickshell-hyprland-popup-notifications"
    implicitWidth: 360
    implicitHeight: 94 + root.listHeight + 44
    visible: false

    onVisibleChanged: {
        if (visible && root.notificationService) {
            root.notificationService.markAllRead();
        }
    }

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

            Column {
                anchors.fill: parent
                anchors.margins: Theme.space16
                spacing: Theme.space8

                Item {
                    width: parent.width
                    height: 30

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        spacing: 8

                        Text {
                            text: root.notificationService && root.notificationService.doNotDisturb
                                ? "notifications_off"
                                : "notifications"
                            color: root.notificationService && root.notificationService.doNotDisturb
                                ? Theme.warning
                                : Theme.accent
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Notifications"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.titleMediumSize
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.notificationCount > 0 ? String(root.notificationCount) : ""
                            color: Theme.muted
                            font.family: "Roboto Flex"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: 104
                        height: 28
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.shapeMedium
                        color: dndMouse.containsMouse
                            ? Theme.surfaceContainerHighest
                            : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            height: 20
                            spacing: 5

                            Text {
                                height: parent.height
                                text: root.notificationService && root.notificationService.doNotDisturb
                                    ? "notifications_off"
                                    : "notifications_active"
                                color: root.notificationService && root.notificationService.doNotDisturb
                                    ? Theme.warning
                                    : Theme.text
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                height: parent.height
                                text: "DND"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.labelSmallSize
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: dndMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.notificationService) {
                                    root.notificationService.toggleDoNotDisturb();
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 28
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.shapeMedium
                        color: clearMouse.containsMouse ? Theme.dangerSurface : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Text {
                            anchors.centerIn: parent
                            text: "delete_sweep"
                            color: Theme.danger
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 17
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.notificationService) {
                                    root.notificationService.clearAll();
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: notificationList
                    width: parent.width
                    height: root.listHeight
                    clip: true
                    spacing: 8
                    model: root.notificationService ? root.notificationService.notifications : null

                    delegate: NotificationCard {
                        required property var modelData

                        width: notificationList.width
                        notification: modelData
                        notificationService: root.notificationService
                    }
                }

                Text {
                    width: parent.width
                    height: root.notificationCount === 0 ? 62 : 0
                    visible: root.notificationCount === 0
                    text: "No notifications"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyMediumSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    height: 28
                    text: "History is kept while Quickshell is running"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSmallSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
