import "."
import QtQuick

Item {
    id: root

    property string title: ""
    property string description: ""
    property string muteLabel: "Mute speakers"
    property string icon: "volume_up"
    property real volume: 0
    property bool muted: false
    property bool available: true
    property bool focusOnShow: false
    property color accentColor: Theme.accent
    property color activeOnColor: Theme.onAccent

    signal requestVolume(real value)
    signal requestMute()

    function syncVolumeSlider() {
        if (!volumeSlider.pressed)
            volumeSlider.value = root.available ? root.volume : 0;
    }

    implicitWidth: 328
    implicitHeight: 104

    Column {
        anchors.fill: parent
        spacing: Theme.space4

        Item {
            id: header

            width: parent.width
            height: 48

            Text {
                id: channelIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: parent.height
                text: root.icon
                color: root.available ? root.accentColor : Theme.muted
                font.family: "Material Symbols Rounded"
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                anchors.left: channelIcon.right
                anchors.leftMargin: Theme.space8
                anchors.right: percentage.left
                anchors.rightMargin: Theme.space8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: root.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodyMediumSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.available ? (root.description.length > 0 ? root.description : "Default device") + " · " + (root.muted ? "Muted" : "Active") : "No default device detected"
                    color: root.available && root.muted ? Theme.warning : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSmallSize
                    elide: Text.ElideRight
                }

            }

            MaterialSwitch {
                id: muteSwitch

                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.switchTrackWidth
                height: 48
                checked: root.available && !root.muted
                enabled: root.available
                activeColor: root.accentColor
                activeOnColor: root.activeOnColor
                accessibleName: root.title.length > 0 ? root.title + " enabled" : root.muteLabel
                accessibleDescription: root.available ? (root.muted ? "Currently muted. Toggle to unmute." : "Currently active. Toggle to mute.") : "No default device detected"
                onToggled: root.requestMute()
            }

            Text {
                id: percentage

                anchors.right: muteSwitch.left
                anchors.rightMargin: Theme.space8
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                text: root.available ? Math.round(root.volume * 100) + "%" : "--"
                color: root.available ? Theme.text : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelMediumSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

        }

        MaterialSlider {
            id: volumeSlider

            width: parent.width
            height: 48
            from: 0
            to: 1
            stepSize: 0.01
            live: true
            enabled: root.available
            focus: root.focusOnShow && root.available
            value: root.available ? root.volume : 0
            activeColor: root.accentColor
            activeOnColor: root.activeOnColor
            accessibleName: root.title + " volume"
            accessibleDescription: root.description
            onMoved: root.requestVolume(value)
        }

    }

    Connections {
        function onVolumeChanged() {
            root.syncVolumeSlider();

        }

        function onAvailableChanged() {
            root.syncVolumeSlider();
        }

        function onMutedChanged() {
            if (!muteSwitch.down)
                muteSwitch.checked = root.available && !root.muted;

        }

        target: root
    }

}
