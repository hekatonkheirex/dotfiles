import QtQuick
import "Singletons"
import "components"
import "surfaces"
import "../config"

Item {
    id: pill

    property real s: 1
    property string surface: ""
    property bool hovered: false
    property bool pinned: false

    readonly property bool held: pinned
    readonly property bool expanded: hovered || held || surface.length > 0
    readonly property bool mixerOpen: surface === "mixer"

    readonly property real restWidth: (restRow.implicitWidth + 28) * s
    readonly property real restHeight: 38 * s
    readonly property real mixerWidth: 280 * s

    signal requestSurface(string name)
    signal requestClose()

    width: mixerOpen ? mixerWidth : restWidth
    height: mixerOpen ? (audioSurface.implicitHeight + 16) * s : restHeight

    Behavior on width {
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    HoverHandler {
        enabled: pill.surface.length === 0
        onHoveredChanged: pill.hovered = hovered
    }

    Rectangle {
        anchors.fill: parent
        radius: pill.mixerOpen ? 18 * pill.s : height / 2
        color: Colors.surfaceContainerHigh
        border.width: 1
        border.color: Colors.outlineVariant
        clip: true

        Behavior on radius {
            NumberAnimation { duration: Motion.morph; easing.type: Easing.OutCubic }
        }

        Row {
            id: restRow
            anchors.centerIn: parent
            spacing: 10 * pill.s
            opacity: pill.mixerOpen ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }

            WorkspaceDots {
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 20 * pill.s
                height: 20 * pill.s
                radius: width / 2
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "" // volume_up, Material Symbols
                    font.family: Config.iconFont
                    font.pixelSize: Config.iconSize
                    color: Colors.fgSurface
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.requestSurface(pill.mixerOpen ? "" : "mixer")
                }
            }
        }

        AudioSurface {
            id: audioSurface
            anchors.fill: parent
            anchors.margins: 0
            opacity: pill.mixerOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }
    }

    Keys.onEscapePressed: pill.requestClose()
}
