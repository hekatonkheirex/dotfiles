import QtQuick

import Quickshell
import Quickshell.Widgets

import "."

Item {
    id: root

    property var notification
    property var notificationService
    property bool toast: false

    readonly property bool hasBody: root.notification
        && root.notification.body
        && root.notification.body.length > 0
    readonly property var visibleActions: root.notification
        && root.notification.actions
        ? root.notification.actions.filter(function(action) {
            return action && action.text && String(action.text).trim().length > 0;
        })
        : []
    readonly property bool hasActions: root.notification
        && root.visibleActions.length > 0
    readonly property string iconUrl: root.iconSource(root.notification
        ? (root.notification.image || root.notification.appIcon)
        : "")

    implicitHeight: 76 + (root.hasBody ? 42 : 0) + (root.hasActions ? 32 : 0)

    function iconSource(value) {
        if (!value || value.length === 0) {
            return "";
        }
        if (value.indexOf("://") !== -1) {
            return value;
        }
        if (value.indexOf("/") === 0) {
            return "file://" + value;
        }
        return Quickshell.iconPath(value, "");
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeLarge
        color: root.toast ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
        border.width: 1
        border.color: Theme.outlineVariant
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.notificationService && root.notification) {
                root.notificationService.markRead(root.notification);
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.space12
        spacing: Theme.space4

        Row {
            width: parent.width
            height: 32
            spacing: Theme.space8

            Item {
                width: 32
                height: 32

                IconImage {
                    anchors.fill: parent
                    source: root.iconUrl
                    visible: root.iconUrl.length > 0
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconUrl.length === 0
                    text: "notifications"
                    color: Theme.accentAlt
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                }
            }

            Column {
                width: parent.width - 70
                height: parent.height
                spacing: 0

                Text {
                    width: parent.width
                    text: root.notification ? root.notification.appName : "Notifications"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelMediumSize
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.notification ? root.notification.summary : ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleMediumSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Text {
                width: 22
                height: 32
                text: "close"
                color: closeMouse.containsMouse ? Theme.danger : Theme.muted
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.notificationService || !root.notification) {
                            return;
                        }
                        if (root.toast) {
                            root.notificationService.closeToast();
                        } else {
                            root.notificationService.dismiss(root.notification);
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            height: root.hasBody ? 42 : 0
            visible: root.hasBody
            text: root.notification ? root.notification.body : ""
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodyMediumSize
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            clip: true
        }

        Row {
            width: parent.width
            height: root.hasActions ? 30 : 0
            visible: root.hasActions
            spacing: Theme.space4

            Repeater {
                model: root.visibleActions

                delegate: Rectangle {
                    required property var modelData

                    width: Math.min(150, actionText.implicitWidth + 20)
                    height: 28
                    radius: Theme.shapeMedium
                    color: actionMouse.containsMouse ? Theme.accentSurface : Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelMediumSize
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.notificationService && root.notification) {
                                root.notificationService.invokeAction(root.notification, modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
