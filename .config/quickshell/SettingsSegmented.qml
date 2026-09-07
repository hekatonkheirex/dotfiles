import QtQuick

import "."

Item {
    id: root

    property var options: []
    property string value: ""
    property bool enabled: true
    signal selected(string value)

    implicitWidth: row.implicitWidth
    implicitHeight: 38
    opacity: root.enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant
    }

    Row {
        id: row
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        Repeater {
            model: root.options

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: Math.max(62, optionLabel.implicitWidth + 28)
                height: row.height
                radius: root.value === modelData.value ? Theme.shapeMedium : 0
                color: root.value === modelData.value ? Theme.accentSurface : "transparent"
                border.width: root.value === modelData.value ? 1 : 0
                border.color: Theme.accent

                Text {
                    id: optionLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelMediumSize
                    font.weight: root.value === modelData.value ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(modelData.value)
                }
            }
        }
    }
}
