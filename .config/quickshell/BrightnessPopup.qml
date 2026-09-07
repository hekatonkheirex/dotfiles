import "."
import QtQuick

PopupPanel {
    id: root

    property int value: 0

    signal requestValue(int value)

    function bounded(value) {
        return Math.max(0, Math.min(100, value));
    }

    panelNamespace: "quickshell-hyprland-popup-brightness"
    focusable: true
    implicitWidth: 288
    implicitHeight: brightnessColumn.implicitHeight + Theme.space16 * 2
    visible: false

    PopupMotion {
        revealed: root.visible

        Rectangle {
            anchors.fill: parent
            radius: Theme.shapeExtraLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: brightnessColumn

                anchors.fill: parent
                anchors.margins: Theme.space16
                spacing: Theme.space8

                Item {
                    width: parent.width
                    height: 24

                    Text {
                        id: brightnessIcon

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: parent.height
                        text: "brightness_medium"
                        color: Theme.accent
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.left: brightnessIcon.right
                        anchors.leftMargin: Theme.space8
                        anchors.right: brightnessValue.left
                        anchors.rightMargin: Theme.space8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Screen brightness"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodyMediumSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        id: brightnessValue

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        text: root.value >= 0 ? root.value + "%" : "--"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelMediumSize
                        horizontalAlignment: Text.AlignRight
                    }

                }

                MaterialSlider {
                    id: brightnessSlider

                    width: parent.width
                    height: 48
                    from: 0
                    to: 100
                    stepSize: 1
                    live: true
                    focus: root.visible
                    value: Math.max(0, root.value)
                    activeColor: Theme.accent
                    accessibleName: "Screen brightness"
                    accessibleDescription: "Adjust the active backlight device"
                    onMoved: root.requestValue(Math.round(value))

                    Connections {
                        function onValueChanged() {
                            if (!brightnessSlider.pressed)
                                brightnessSlider.value = Math.max(0, root.value);

                        }

                        target: root
                    }

                }

                Text {
                    width: parent.width
                    text: "Uses the active backlight device"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSmallSize
                    horizontalAlignment: Text.AlignHCenter
                }

            }

        }

    }

}
