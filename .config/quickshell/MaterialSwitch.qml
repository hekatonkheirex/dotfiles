import "."
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property bool checked: false
    property color activeColor: Theme.accent
    property color activeOnColor: Theme.onAccent
    property string accessibleName: ""
    property string accessibleDescription: ""

    signal toggled(bool checked)

    implicitWidth: Theme.switchTrackWidth
    implicitHeight: 48
    opacity: root.enabled ? 1 : 0.45

    Switch {
        id: control

        anchors.fill: parent
        text: ""
        padding: 0
        spacing: 0
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        checked: root.checked
        Accessible.name: root.accessibleName
        Accessible.description: root.accessibleDescription
        onToggled: root.toggled(checked)

        indicator: Item {
            id: indicator

            x: (control.width - width) / 2
            y: (control.height - height) / 2
            width: Theme.switchTrackWidth
            height: Theme.switchTrackHeight

            Rectangle {
                id: track

                anchors.fill: parent
                radius: Theme.shapeFull
                color: control.checked ? root.activeColor : Theme.surfaceContainerHighest
                border.width: control.checked ? 0 : 2
                border.color: Theme.outline
            }

            Rectangle {
                visible: control.hovered || control.down
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: Theme.shapeFull
                color: root.activeColor
                opacity: control.down ? 0.16 : 0.1
            }

            Rectangle {
                id: thumb

                width: control.checked ? Theme.switchCheckedThumbSize : Theme.switchUncheckedThumbSize
                height: width
                radius: Theme.shapeFull
                anchors.verticalCenter: parent.verticalCenter
                x: control.checked ? parent.width - width - Theme.switchThumbInset : Theme.switchThumbInset
                color: control.checked ? root.activeOnColor : Theme.outline

                Text {
                    visible: control.checked
                    anchors.centerIn: parent
                    text: "check"
                    color: root.activeColor
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.motionShort
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.motionShort
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Rectangle {
                visible: control.visualFocus
                anchors.centerIn: parent
                width: parent.width + 8
                height: parent.height + 8
                radius: Theme.shapeFull
                color: "transparent"
                border.width: 2
                border.color: root.activeColor
                opacity: 0.85
            }

        }

        contentItem: Item {
        }

    }

    Connections {
        function onCheckedChanged() {
            if (!control.down)
                control.checked = root.checked;

        }

        target: root
    }

}
