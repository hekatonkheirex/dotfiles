import QtQuick
import QtQuick.Controls

import Quickshell
import Quickshell.Io

import "."

PopupPanel {
    id: root

    property string pendingLabel: ""
    property var pendingCommand: []
    property bool caffeineEnabled: false
    property bool bluetoothAvailable: false
    property bool bluetoothPowered: false
    readonly property var lockCommand: [
        "quickshell", "ipc", "--path", Quickshell.shellDir, "call", "session", "lock"
    ]

    signal requestToggleCaffeine()
    signal requestSettings()

    panelNamespace: "quickshell-hyprland-popup-power"

    implicitWidth: Math.max(quickSettingsRow.implicitWidth, actionRow.implicitWidth) + Theme.space16 * 2
    implicitHeight: powerColumn.implicitHeight + Theme.space16 * 2
    visible: false

    function requestConfirmation(command, label) {
        root.pendingCommand = command;
        root.pendingLabel = label;
    }

    function execute(command) {
        root.visible = false;
        root.pendingCommand = [];
        root.pendingLabel = "";
        Quickshell.execDetached(command);
    }

    function refreshBluetooth() {
        bluetoothReader.exec(["bluetoothctl", "show"]);
    }

    function updateBluetooth(raw) {
        var match = raw.match(/Powered:\s+(yes|no)/i);
        root.bluetoothAvailable = match !== null;
        if (match)
            root.bluetoothPowered = match[1].toLowerCase() === "yes";

    }

    function toggleBluetooth() {
        if (!root.bluetoothAvailable)
            return ;

        bluetoothSetter.exec(["bluetoothctl", "power", root.bluetoothPowered ? "off" : "on"]);
    }

    onVisibleChanged: {
        if (!visible) {
            root.pendingCommand = [];
            root.pendingLabel = "";
        } else
            root.refreshBluetooth();
    }

    Component.onCompleted: root.refreshBluetooth()

    Process {
        id: bluetoothReader

        stdout: StdioCollector {
            onStreamFinished: root.updateBluetooth(this.text)
        }

    }

    Process {
        id: bluetoothSetter

        onExited: root.refreshBluetooth()
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
                id: powerColumn

                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

            Text {
                text: "Quick Settings"
                color: Theme.text
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                leftPadding: 4
                bottomPadding: 4
            }

            Row {
                id: quickSettingsRow

                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.space8

                PopupIconButton {
                    icon: "coffee"
                    label: "Caffeine"
                    active: root.caffeineEnabled
                    accessibleDescription: root.caffeineEnabled
                        ? "Caffeine mode is active. Toggle to disable."
                        : "Caffeine mode is inactive. Toggle to enable."
                    onActivated: root.requestToggleCaffeine()
                }

                PopupIconButton {
                    icon: root.bluetoothPowered ? "bluetooth" : "bluetooth_disabled"
                    label: "Bluetooth"
                    enabled: root.bluetoothAvailable
                    active: root.bluetoothPowered
                    accessibleDescription: root.bluetoothAvailable
                        ? (root.bluetoothPowered ? "Bluetooth is on. Toggle to turn it off." : "Bluetooth is off. Toggle to turn it on.")
                        : "Bluetooth is unavailable."
                    onActivated: root.toggleBluetooth()
                }

                PopupIconButton {
                    icon: "lock"
                    label: "Lock"
                    accessibleDescription: "Lock the session"
                    onActivated: root.execute(root.lockCommand)
                }

                PopupIconButton {
                    icon: "settings"
                    label: "Settings"
                    accessibleDescription: "Open Quick Settings"
                    onActivated: root.requestSettings()
                }
            }

            Row {
                id: actionRow

                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.space8

                Repeater {
                    model: [
                        { icon: "logout", label: "Log out", command: ["hyprctl", "dispatch", "hl.dsp.exit()"], confirm: true },
                        { icon: "bedtime", label: "Suspend", command: ["systemctl", "suspend"], confirm: true },
                        { icon: "restart_alt", label: "Reboot", command: ["systemctl", "reboot"], confirm: true },
                        { icon: "power_settings_new", label: "Power off", command: ["systemctl", "poweroff"], confirm: true }
                    ]

                    delegate: PopupIconButton {
                        required property var modelData

                        icon: modelData.icon
                        label: modelData.label
                        destructive: modelData.confirm
                        activeColor: modelData.confirm ? Theme.danger : Theme.accent
                        activeForeground: modelData.confirm ? Theme.onDanger : Theme.onAccent
                        accessibleDescription: modelData.confirm ? "Opens a confirmation prompt" : "Activates immediately"
                        onActivated: modelData.confirm
                            ? root.requestConfirmation(modelData.command, modelData.label)
                            : root.execute(modelData.command)
                    }
                }
            }

            Rectangle {
                visible: root.pendingCommand.length > 0
                width: parent.width
                height: 64
                radius: Theme.shapeLarge
                color: Theme.dangerSurface

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        width: parent.width
                        text: "Confirm " + root.pendingLabel + "?"
                        color: Theme.text
                        font.family: "Roboto Flex"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Rectangle {
                            width: 76
                            height: 24
                        radius: Theme.shapeMedium
                            color: Theme.danger

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: Theme.onDanger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.labelSmallSize
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.execute(root.pendingCommand)
                            }
                        }

                        Rectangle {
                            width: 76
                            height: 24
                        radius: Theme.shapeMedium
                        color: Theme.surfaceContainerHigh

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.labelSmallSize
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.pendingCommand = [];
                                    root.pendingLabel = "";
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }
}
