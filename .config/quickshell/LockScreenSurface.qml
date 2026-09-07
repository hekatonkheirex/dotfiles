import QtQuick

import Quickshell
import Quickshell.Wayland

import "."

WlSessionLockSurface {
    id: root

    required property var controller

    color: Theme.background

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background

        Column {
            anchors.centerIn: parent
            width: Math.max(0, Math.min(420, parent.width - 48))
            spacing: 22

            Column {
                width: parent.width
                spacing: 2

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 54
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleMediumSize
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 300
                radius: Theme.shapeExtraLarge
                color: Theme.surfaceContainer
                border.width: 1
                border.color: Theme.outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 14

                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.surfaceContainerHigh
                        clip: true

                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            source: root.controller.avatarSource
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: avatarImage.status !== Image.Ready
                            text: root.controller.username.charAt(0).toUpperCase()
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: parent.width
                        text: root.controller.username
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.titleMediumSize
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "Unlock to continue"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelMediumSize
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        id: passwordField
                        width: parent.width
                        height: 48
                        radius: Theme.shapeMedium
                        color: Theme.surfaceContainerHigh
                        border.width: passwordInput.activeFocus ? 2 : 1
                        border.color: passwordInput.activeFocus ? Theme.accent : Theme.outlineVariant

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            selectionColor: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.bodyMediumSize
                            echoMode: TextInput.Password
                            clip: true
                            enabled: !root.controller.authenticating
                            focus: true

                            Keys.onReturnPressed: function(event) {
                                root.controller.authenticate(text);
                                event.accepted = true;
                            }

                            Keys.onEnterPressed: function(event) {
                                root.controller.authenticate(text);
                                event.accepted = true;
                            }

                            Component.onCompleted: forceActiveFocus()

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                visible: passwordInput.text.length === 0
                                text: root.controller.authenticating ? "Checking..." : "Password"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.bodyMediumSize
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: Theme.shapeMedium
                        color: root.controller.authenticating ? Theme.surfaceContainerHigh : Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: root.controller.authenticating ? "Checking..." : "Unlock"
                            color: root.controller.authenticating ? Theme.muted : Theme.onAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.labelMediumSize
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.controller.authenticating
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.controller.authenticate(passwordInput.text)
                        }
                    }

                    Text {
                        width: parent.width
                        height: 18
                        text: root.controller.statusMessage
                        color: root.controller.statusIsError ? Theme.danger : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelSmallSize
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Connections {
        target: root.controller

        function onAuthenticationResult(success) {
            passwordInput.text = "";
            if (!success && root.controller.locked) {
                passwordInput.forceActiveFocus();
            }
        }
    }
}
