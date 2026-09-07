import QtQuick

import Quickshell

import "."

PopupPanel {
    id: root

    property string query: ""
    property int selectedIndex: 0

    panelNamespace: "quickshell-hyprland-popup-launcher"
    focusable: true

    implicitWidth: 360
    implicitHeight: 500
    visible: false

    function launchSelected() {
        var entries = filteredApps.values;
        if (entries.length === 0) {
            return;
        }

        var index = Math.max(0, Math.min(root.selectedIndex, entries.length - 1));
        entries[index].execute();
        root.visible = false;
    }

    onVisibleChanged: {
        if (visible) {
            root.query = "";
            root.selectedIndex = 0;
            focusTimer.restart();
        }
    }

    onQueryChanged: root.selectedIndex = 0;

    Timer {
        id: focusTimer
        interval: 0
        repeat: false
        onTriggered: search.forceActiveFocus()
    }

    ScriptModel {
        id: filteredApps
        objectProp: "id"
        values: {
            var needle = root.query.trim().toLowerCase();
            var entries = [...DesktopEntries.applications.values];

            entries.sort(function(left, right) {
                return left.name.localeCompare(right.name);
            });

            if (needle.length === 0) {
                return entries.slice(0, 24);
            }

            return entries.filter(function(entry) {
                var keywords = entry.keywords || [];
                var haystack = [entry.name, entry.genericName, entry.comment]
                    .concat(keywords)
                    .join(" ")
                    .toLowerCase();
                return haystack.indexOf(needle) !== -1;
            }).slice(0, 24);
        }
    }

    PopupMotion {
        revealed: root.visible

        Rectangle {
            id: card
            anchors.fill: parent
            anchors.margins: 1
            anchors.topMargin: 0
            radius: Theme.shapeExtraLarge
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Theme.outlineVariant

            Rectangle {
                id: searchBox
                x: 12
                y: 12
                width: parent.width - 24
                height: 48
                radius: Theme.shapeMedium
                color: Theme.surfaceContainerHighest
                border.width: search.activeFocus ? 2 : 1
                border.color: search.activeFocus ? Theme.accent : Theme.outlineVariant

            Text {
                visible: search.text.length === 0
                anchors.left: parent.left
                anchors.leftMargin: 48
                anchors.verticalCenter: parent.verticalCenter
                text: "Search applications"
                color: Theme.muted
                font.family: "Roboto Flex"
                font.pixelSize: 14
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                visible: true
                color: search.activeFocus ? Theme.accent : Theme.muted
            }

            TextInput {
                id: search
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 48
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.background
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyMediumSize
                text: root.query
                onTextChanged: root.query = text

                Keys.onEscapePressed: function(event) {
                    root.visible = false;
                    event.accepted = true;
                }

                Keys.onReturnPressed: function(event) {
                    root.launchSelected();
                    event.accepted = true;
                }

                Keys.onPressed: function(event) {
                    if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down) {
                        return;
                    }

                    var count = filteredApps.values.length;
                    if (count > 0) {
                        var delta = event.key === Qt.Key_Down ? 1 : -1;
                        root.selectedIndex = Math.max(
                            0,
                            Math.min(count - 1, root.selectedIndex + delta)
                        );
                        results.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                    }
                    event.accepted = true;
                }
            }
            }

            ListView {
                id: results
                anchors.top: searchBox.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: footer.top
                anchors.margins: 12
                spacing: 4
                clip: true
                model: filteredApps

            delegate: Item {
                required property var modelData
                required property int index

                width: results.width
                height: 48

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.shapeMedium
                    color: resultMouse.containsMouse
                        ? Theme.surfaceContainerHighest
                        : (index === root.selectedIndex ? Theme.accentSurface : "transparent")
                    border.color: index === root.selectedIndex ? Theme.accent : Theme.outlineVariant
                    border.width: index === root.selectedIndex ? 1 : 0
                }

                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    sourceSize.width: 28
                    sourceSize.height: 28
                    fillMode: Image.PreserveAspectFit
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 52
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: modelData.name
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodyMediumSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.genericName.length > 0 ? modelData.genericName : modelData.comment
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelSmallSize
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }

                MouseArea {
                    id: resultMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = index
                    onClicked: {
                        modelData.execute();
                        root.visible = false;
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: results.count === 0
                text: root.query.length > 0 ? "No matching applications" : "No applications found"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyMediumSize
            }
            }

            Text {
                id: footer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 14
                text: "↑↓ select  ·  Enter launch  ·  Esc close"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSmallSize
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
