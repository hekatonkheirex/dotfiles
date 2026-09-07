import "."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

PopupPanel {
    id: root

    property var battery
    property int cycleCount: -1
    property string detectedModel: ""
    property bool detailsLoaded: false
    readonly property bool batteryReady: root.battery !== null && root.battery !== undefined && root.battery.ready
    readonly property int batteryPercent: root.batteryReady ? root.percentValue(root.battery.percentage) : -1
    readonly property bool charging: root.batteryReady && root.battery.changeRate > 0
    readonly property bool discharging: root.batteryReady && (root.battery.changeRate < 0 || UPower.onBattery)
    readonly property string batteryIcon: !root.batteryReady ? "battery_unknown" : (root.charging ? "battery_charging_full" : (root.batteryPercent <= 15 ? "battery_alert" : (root.batteryPercent >= 90 ? "battery_full" : (root.batteryPercent >= 60 ? "battery_6_bar" : (root.batteryPercent >= 30 ? "battery_3_bar" : "battery_1_bar")))))
    readonly property string statusText: !root.batteryReady ? "Battery unavailable" : (root.charging ? "Charging" : (root.discharging ? "Discharging" : (root.batteryPercent >= 100 ? "Fully charged" : "Connected to power")))
    readonly property color statusColor: !root.batteryReady ? Theme.muted : (root.batteryPercent <= 15 && !root.charging ? Theme.danger : (root.charging ? Theme.positive : Theme.accent))
    readonly property string timeLabel: {
        if (!root.batteryReady)
            return "Not available";

        if (root.charging)
            return root.battery.timeToFull > 0 ? "About " + root.formatDuration(root.battery.timeToFull) : (root.batteryPercent >= 100 ? "Full" : "Not available");

        return root.battery.timeToEmpty > 0 ? "About " + root.formatDuration(root.battery.timeToEmpty) : (root.batteryPercent <= 0 ? "Empty" : "Not available");
    }
    readonly property string healthLabel: root.batteryReady && root.battery.healthSupported ? root.percentLabel(root.battery.healthPercentage) : "Not available"
    readonly property string energyLabel: root.batteryReady && root.battery.energyCapacity > 0 ? root.battery.energy.toFixed(1) + " / " + root.battery.energyCapacity.toFixed(1) + " Wh" : "Not available"
    readonly property string rateLabel: root.batteryReady && Math.abs(root.battery.changeRate) > 0.01 ? Math.abs(root.battery.changeRate).toFixed(1) + " W" : "Not available"
    readonly property string modelLabel: root.detectedModel.length > 0 ? root.detectedModel : (root.batteryReady && root.battery.model ? root.battery.model : "System battery")
    readonly property var detailRows: [{
        "label": "Status",
        "value": root.statusText
    }, {
        "label": root.charging ? "Until full" : "Time remaining",
        "value": root.timeLabel
    }, {
        "label": "Battery health",
        "value": root.healthLabel
    }, {
        "label": "Charge cycles",
        "value": root.cycleCount >= 0 ? String(root.cycleCount) : "Not available"
    }, {
        "label": "Energy",
        "value": root.energyLabel
    }, {
        "label": "Power rate",
        "value": root.rateLabel
    }]

    function formatDuration(seconds) {
        if (typeof seconds !== "number" || !isFinite(seconds) || seconds <= 0)
            return "Not available";

        var minutes = Math.max(1, Math.round(seconds / 60));
        if (minutes < 60)
            return minutes + " min";

        var hours = Math.floor(minutes / 60);
        var remainingMinutes = minutes % 60;
        return hours + " h" + (remainingMinutes > 0 ? " " + remainingMinutes + " min" : "");
    }

    function percentValue(value) {
        var normalized = value > 1 ? value / 100 : value;
        return Math.round(Math.max(0, Math.min(1, normalized)) * 100);
    }

    function percentLabel(value) {
        return root.percentValue(value) + "%";
    }

    function refreshDetails() {
        root.cycleCount = -1;
        root.detectedModel = "";
        root.detailsLoaded = false;
        batteryDevicesReader.exec(["upower", "-e"]);
    }

    function updateBatteryDevicePath(raw) {
        var lines = raw.trim().split(/\r?\n/);
        var path = "";
        for (var index = 0; index < lines.length; index++) {
            var candidate = lines[index].trim();
            if (/\/battery(?:_|\/|$)/i.test(candidate)) {
                path = candidate;
                break;
            }
        }
        if (path.length === 0) {
            root.detailsLoaded = true;
            return ;
        }
        batteryDetailsReader.exec(["upower", "-i", path]);
    }

    function updateBatteryDetails(raw) {
        var cycles = raw.match(/^\s*charge-cycles:\s*([0-9]+(?:\.[0-9]+)?)/mi);
        if (cycles)
            root.cycleCount = Math.round(parseFloat(cycles[1]));

        var model = raw.match(/^\s*model:\s*(.+)$/mi);
        if (model && model[1].trim().length > 0)
            root.detectedModel = model[1].trim();

        root.detailsLoaded = true;
    }

    panelNamespace: "quickshell-hyprland-popup-battery"
    implicitWidth: 336
    implicitHeight: batteryColumn.implicitHeight + Theme.space16 * 2
    visible: false

    PopupMotion {
        revealed: root.visible

        Rectangle {
            anchors.fill: parent
            radius: Theme.shapeExtraLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: batteryColumn

                anchors.fill: parent
                anchors.margins: Theme.space16
                spacing: Theme.space12

                Row {
                    width: parent.width
                    height: 54
                    spacing: Theme.space12

                    Text {
                        text: root.batteryIcon
                        color: root.statusColor
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 34
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Battery"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.titleMediumSize
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.modelLabel
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.labelSmallSize
                            elide: Text.ElideRight
                        }

                    }

                    Item {
                        width: 1
                        height: 1
                    }

                    Text {
                        text: root.batteryReady ? root.batteryPercent + "%" : "--"
                        color: root.statusColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.titleMediumSize
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Rectangle {
                    width: parent.width
                    height: 8
                    radius: Theme.shapeFull
                    color: Theme.surfaceContainerHighest

                    Rectangle {
                        width: parent.width * Math.max(0, root.batteryPercent) / 100
                        height: parent.height
                        radius: Theme.shapeFull
                        color: root.statusColor
                    }

                }

                Rectangle {
                    id: detailsDivider

                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.7
                }

                Column {
                    id: detailRows

                    width: parent.width
                    height: root.detailRows.length * 30
                    spacing: 0

                    Repeater {
                        model: root.detailRows

                        delegate: Item {
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 30

                            Row {
                                anchors.fill: parent
                                spacing: Theme.space8

                                Text {
                                    width: parent.width * 0.52
                                    text: modelData.label
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.labelSmallSize
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    width: parent.width * 0.48 - Theme.space8
                                    text: modelData.value
                                    color: modelData.label === "Status" ? root.statusColor : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.labelSmallSize
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                            }

                            Rectangle {
                                visible: index < root.detailRows.length - 1
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Theme.outlineVariant
                            }

                        }

                    }

                }

                Text {
                    width: parent.width
                    text: root.detailsLoaded ? "Battery details are reported by UPower" : "Reading battery details…"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSmallSize
                    horizontalAlignment: Text.AlignHCenter
                }

            }

        }

    }

    Process {
        id: batteryDevicesReader

        stdout: StdioCollector {
            onStreamFinished: root.updateBatteryDevicePath(this.text)
        }

    }

    Process {
        id: batteryDetailsReader

        stdout: StdioCollector {
            onStreamFinished: root.updateBatteryDetails(this.text)
        }

    }

    Connections {
        function onVisibleChanged() {
            if (root.visible)
                root.refreshDetails();

        }

        target: root
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: root.refreshDetails()
    }

}
