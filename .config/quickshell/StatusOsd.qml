import QtQuick

import Quickshell
import Quickshell.Wayland

import "."

PanelWindow {
    id: root

    property var targetScreen
    property string icon: ""
    property string title: ""
    property int value: -1
    property color accentColor: Theme.accent
    property bool osdVisible: false

    screen: root.targetScreen
    visible: false
    implicitWidth: root.targetScreen && root.targetScreen.width ? root.targetScreen.width : 320
    implicitHeight: 22 + Theme.space8 + 48 + Theme.space16 * 2
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
    }

    margins {
        top: 52
        left: 0
        right: 0
    }

    WlrLayershell.namespace: "quickshell-hyprland-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function showVolume(level, muted) {
        root.icon = muted ? "volume_off" : (level <= 0 ? "volume_off" : "volume_up");
        root.title = muted ? "Volume muted" : "Volume";
        root.value = Math.max(0, Math.min(100, Math.round(level)));
        root.accentColor = muted ? Theme.warning : Theme.accent;
        root.show();
    }

    function showBrightness(level) {
        root.icon = "brightness_medium";
        root.title = "Brightness";
        root.value = Math.max(0, Math.min(100, Math.round(level)));
        root.accentColor = Theme.accent;
        root.show();
    }

    function showKeyboardBrightness(level) {
        root.icon = "keyboard";
        root.title = "Keyboard brightness";
        root.value = Math.max(0, Math.min(100, Math.round(level)));
        root.accentColor = Theme.accent;
        root.show();
    }

    function show() {
        root.osdVisible = true;
        root.visible = true;
        hideTimer.restart();
    }

    Rectangle {
        width: 320
        height: root.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        radius: Theme.shapeExtraLarge
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant

        Column {
            anchors.fill: parent
            anchors.margins: Theme.space16
            spacing: 8

            Row {
                width: parent.width
                height: 22
                spacing: 8

                Text {
                    text: root.icon
                    color: root.accentColor
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: root.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyMediumSize
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Item { width: 1; height: 1 }

                Text {
                    text: root.value >= 0 ? root.value + "%" : ""
                    color: Theme.muted
                    font.family: "Roboto Flex"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MaterialSlider {
                width: parent.width
                height: 48
                from: 0
                to: 100
                value: Math.max(0, root.value)
                enabled: false
                visualOnly: true
                activeColor: root.accentColor
                activeOnColor: Theme.onAccent
                accessibleName: root.title
                accessibleDescription: "Current " + root.title.toLowerCase() + " level"
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1400
        repeat: false
        onTriggered: {
            root.osdVisible = false;
            root.visible = false;
        }
    }
}
