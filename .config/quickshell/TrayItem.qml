import QtQuick

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "."

Item {
    id: root

    property var trayItem

    implicitWidth: 30
    implicitHeight: 32

    function toggleMenu() {
        if (!root.trayItem || !root.trayItem.hasMenu) {
            return;
        }

        if (menuAnchor.visible) {
            menuAnchor.close();
        } else {
            menuAnchor.open();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: mouseArea.containsMouse || menuAnchor.visible
            ? Theme.surfaceContainerHigh
            : "transparent"
        border.width: root.trayItem && root.trayItem.status === Status.NeedsAttention ? 1 : 0
        border.color: Theme.warning
    }

    IconImage {
        id: trayIcon
        anchors.centerIn: parent
        width: 20
        height: 20
        source: root.trayItem ? root.trayItem.icon : ""
        asynchronous: true
    }

    Text {
        anchors.centerIn: parent
        visible: !root.trayItem || !root.trayItem.icon || root.trayItem.icon.length === 0
            || trayIcon.status === Image.Error
        text: "apps"
        color: Theme.muted
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true

        onClicked: function(mouse) {
            if (!root.trayItem) {
                return;
            }

            if (mouse.button === Qt.MiddleButton) {
                if (root.trayItem.hasMenu) {
                    root.toggleMenu();
                } else {
                    root.trayItem.secondaryActivate();
                }
                return;
            }

            if (root.trayItem.onlyMenu && root.trayItem.hasMenu) {
                root.toggleMenu();
            } else {
                root.trayItem.activate();
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor
        menu: root.trayItem && root.trayItem.hasMenu ? root.trayItem.menu : null
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Top
        anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX
    }
}
