import QtQuick

Item {
    id: root

    property bool revealed: false
    property int duration: Theme.motionMedium

    default property alias content: movingContent.data

    anchors.fill: parent
    clip: true

    Item {
        id: movingContent

        width: root.width
        height: root.height
        y: root.revealed ? 0 : -root.height
        opacity: root.revealed ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.OutCubic
            }
        }
    }
}
