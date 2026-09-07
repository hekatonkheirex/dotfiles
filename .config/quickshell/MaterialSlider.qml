import "."
import QtQuick
import QtQuick.Controls

Slider {
    id: root

    property string accessibleName: ""
    property string accessibleDescription: ""
    property color activeColor: Theme.accent
    property color activeOnColor: Theme.onAccent
    property bool visualOnly: false
    readonly property int thumbWidth: Theme.sliderThumbWidth
    readonly property int thumbHeight: Theme.sliderThumbHeight
    property int stopIndicatorCount: 0
    property color activeStopIndicatorColor: Theme.onAccent
    property color inactiveStopIndicatorColor: Theme.accent

    implicitWidth: 240
    implicitHeight: 48
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: root.accessibleName
    Accessible.description: root.accessibleDescription

    background: Item {
        anchors.fill: parent

        Rectangle {
            id: activeTrack

            x: root.leftPadding
            y: root.topPadding + (root.availableHeight - height) / 2
            width: Math.max(0, handle.x - x - Theme.sliderThumbGap)
            height: Theme.sliderTrackHeight
            radius: Theme.shapeSmall
            color: root.enabled || root.visualOnly ? root.activeColor : Theme.outline
        }

        // Keep the outer cap rounded while making the edge facing the
        // handle straight, as in the Material 3 slider treatment.
        Rectangle {
            id: activeTrackInnerEnd

            x: activeTrack.x + Math.max(0, activeTrack.width - Theme.shapeSmall)
            y: activeTrack.y
            width: Math.min(Theme.shapeSmall, activeTrack.width)
            height: activeTrack.height
            radius: 0
            color: activeTrack.color
        }

        Rectangle {
            id: inactiveTrack

            x: handle.x + root.thumbWidth + Theme.sliderThumbGap
            y: root.topPadding + (root.availableHeight - height) / 2
            width: Math.max(0, root.leftPadding + root.availableWidth - x)
            height: Theme.sliderTrackHeight
            radius: Theme.shapeSmall
            color: root.enabled || root.visualOnly ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        }

        Rectangle {
            id: inactiveTrackInnerStart

            x: inactiveTrack.x
            y: inactiveTrack.y
            width: Math.min(Theme.shapeSmall, inactiveTrack.width)
            height: inactiveTrack.height
            radius: 0
            color: inactiveTrack.color
        }

        Repeater {
            model: root.stopIndicatorCount

            delegate: Rectangle {
                required property int index
                readonly property real position: (index + 1) / (root.stopIndicatorCount + 1)

                x: root.leftPadding + position * root.availableWidth - width / 2
                y: root.topPadding + (root.availableHeight - height) / 2
                width: 4
                height: 4
                radius: Theme.shapeFull
                color: position <= root.visualPosition ? root.activeStopIndicatorColor : root.inactiveStopIndicatorColor
            }

        }

    }

    handle: Item {
        id: handle

        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: root.thumbWidth
        implicitHeight: root.thumbHeight

        Rectangle {
            id: stateLayer

            anchors.centerIn: parent
            width: 48
            height: 48
            radius: Theme.shapeFull
            color: root.activeColor
            opacity: root.visualOnly ? 0 : (root.pressed ? 0.16 : (root.hovered ? 0.1 : 0))
        }

        Rectangle {
            id: thumb

            anchors.fill: parent
            radius: Theme.shapeExtraSmall
            color: root.enabled || root.visualOnly ? root.activeColor : Theme.outline
            border.width: root.visualFocus ? 2 : 0
            border.color: root.activeOnColor
        }

        Rectangle {
            visible: root.visualFocus
            anchors.centerIn: parent
            width: 40
            height: 48
            radius: Theme.shapeFull
            color: "transparent"
            border.width: 2
            border.color: root.activeColor
            opacity: 0.85
        }

    }

}
