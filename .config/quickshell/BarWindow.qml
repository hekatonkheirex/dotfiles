import QtQuick

import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    property var settingsWindow
    property var notificationService

    screen: root.modelData
    implicitHeight: 42
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 42

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 0
        left: 0
        right: 0
    }

    WlrLayershell.namespace: "quickshell-hyprland-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    BarContent {
        id: content
        anchors.fill: parent
        barWindow: root
        settingsWindow: root.settingsWindow
        notificationService: root.notificationService
        screen: root.screen
    }

    function toggleLauncher() {
        content.toggleLauncher();
    }

    function toggleNotifications() {
        content.toggleNotifications();
    }

    function toggleSettings() {
        if (root.settingsWindow) {
            root.settingsWindow.toggle();
        }
    }

    function refreshBrightness() {
        content.refreshBrightness();
    }
}
