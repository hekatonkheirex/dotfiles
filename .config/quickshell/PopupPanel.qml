import QtQuick

import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var anchorItem
    property var barWindow
    property string panelNamespace: "quickshell-hyprland-popup"

    default property alias content: contentHost.data

    visible: false
    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    screen: root.barWindow ? root.barWindow.screen : null

    anchors {
        top: true
        left: true
    }

    margins {
        top: 46
        left: 8
    }

    WlrLayershell.namespace: root.panelNamespace
    WlrLayershell.layer: WlrLayer.Overlay

    Item {
        id: contentHost
        anchors.fill: parent
    }

    function updatePosition() {
        var position = root.anchorItem && root.barWindow && root.barWindow.contentItem
            ? root.anchorItem.mapToItem(root.barWindow.contentItem, 0, 0)
            : Qt.point(8, 0);
        var contentWidth = root.width > 0 ? root.width : root.implicitWidth;
        var screenWidth = root.screen && root.screen.width
            ? root.screen.width
            : contentWidth;
        var desiredX = root.anchorItem
            ? position.x + root.anchorItem.width / 2 - contentWidth / 2
            : 8;
        var maximumX = Math.max(0, screenWidth - contentWidth);

        root.margins.left = Math.round(Math.max(0, Math.min(maximumX, desiredX)));
        root.margins.top = root.barWindow
            ? root.barWindow.height + Theme.space4
            : 42 + Theme.space4;
    }

    Timer {
        id: positionTimer
        interval: 0
        repeat: false
        onTriggered: root.updatePosition()
    }

    onVisibleChanged: if (visible) positionTimer.restart()
    onWidthChanged: if (visible) positionTimer.restart()
    onHeightChanged: if (visible) positionTimer.restart()
    onScreenChanged: if (visible) positionTimer.restart()

    Component.onCompleted: positionTimer.restart()
}
