import QtQuick

import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var notificationService
    property var targetScreen
    readonly property var notification: root.notificationService
        ? root.notificationService.currentToast
        : null

    screen: root.targetScreen
    visible: root.notificationService ? root.notificationService.toastVisible : false
    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 390
    implicitHeight: notificationCard.implicitHeight

    anchors {
        top: true
        right: true
    }

    margins {
        top: 54
        right: 16
    }

    WlrLayershell.namespace: "quickshell-hyprland-notification-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    NotificationCard {
        id: notificationCard
        anchors.fill: parent
        notification: root.notification
        notificationService: root.notificationService
        toast: true
    }
}
