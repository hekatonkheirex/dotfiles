import "."
import QtQuick

PopupPanel {
    id: root

    property real volume: 0
    property bool muted: false
    property bool outputAvailable: true
    property string outputDescription: "Default speakers"
    property real inputVolume: 0
    property bool inputMuted: false
    property bool inputAvailable: true
    property string inputDescription: "Default microphone"

    signal requestVolume(real value)
    signal requestMute()
    signal requestInputVolume(real value)
    signal requestInputMute()

    panelNamespace: "quickshell-hyprland-popup-volume"
    focusable: true
    implicitWidth: 336
    implicitHeight: audioColumn.implicitHeight + Theme.space16 * 2
    visible: false

    PopupMotion {
        revealed: root.visible

        Rectangle {
            anchors.fill: parent
            radius: Theme.shapeExtraLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: audioColumn

                anchors.fill: parent
                anchors.margins: Theme.space16
                spacing: Theme.space8

                AudioChannelControl {
                    width: parent.width
                    title: "Speakers"
                    description: root.outputDescription
                    muteLabel: "Mute speakers"
                    icon: root.muted ? "volume_off" : "volume_up"
                    volume: root.volume
                    muted: root.muted
                    available: root.outputAvailable
                    focusOnShow: root.visible
                    accentColor: Theme.accent
                    activeOnColor: Theme.onAccent
                    onRequestVolume: function(value) {
                        root.requestVolume(value);
                    }
                    onRequestMute: root.requestMute()
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.7
                }

                AudioChannelControl {
                    width: parent.width
                    title: "Microphone"
                    description: root.inputDescription
                    muteLabel: "Mute microphone"
                    icon: root.inputMuted ? "mic_off" : "mic"
                    volume: root.inputVolume
                    muted: root.inputMuted
                    available: root.inputAvailable
                    focusOnShow: false
                    accentColor: Theme.accentAlt
                    activeOnColor: Theme.onAccentAlt
                    onRequestVolume: function(value) {
                        root.requestInputVolume(value);
                    }
                    onRequestMute: root.requestInputMute()
                }

            }

        }

    }

}
