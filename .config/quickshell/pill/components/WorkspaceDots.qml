import QtQuick
import "../Singletons"
import "../../config"

Row {
    id: root
    spacing: 6

    Repeater {
        model: Niri.workspaces

        delegate: Item {
            id: delegateItem
            required property var modelData

            readonly property bool active: modelData.isFocused || wsMouse.containsMouse

            width: active ? 28 : 14
            height: 14

            Behavior on width {
                NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: delegateItem.active ? 14 : (modelData.isOccupied ? 8 : 6)
                radius: height / 2

                color: {
                    if (modelData.isFocused) return Colors.primary
                    var base = modelData.isOccupied ? Colors.surfaceContainerHighest : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)
                    return Qt.tint(base, wsMouse.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
                }

                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Behavior on height { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.idx.toString()
                    opacity: delegateItem.active ? 1.0 : 0.0
                    visible: opacity > 0
                    color: modelData.isFocused ? Colors.fgPrimary : Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.weight: modelData.isFocused ? Font.Bold : Font.Normal
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(delegateItem.modelData.idx)
                onWheel: function(wheel) {
                    wheel.accepted = true
                    Niri.scrollWorkspace(wheel.angleDelta.y)
                }
            }
        }
    }
}
