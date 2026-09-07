import "."
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland

Item {
    id: root

    property var barWindow
    property var settingsWindow
    property var notificationService
    property var screen
    property bool caffeineEnabled: false
    property int brightnessPercent: -1
    property var persistentWorkspaceRules: []
    property int workspaceRevision: 0
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool audioReady: audioSink !== null && audioSink !== undefined && audioSink.ready && audioSink.audio !== null && audioSink.audio !== undefined
    readonly property real volume: audioReady ? Math.max(0, Math.min(1, audioSink.audio.volume)) : 0
    readonly property bool audioMuted: audioReady ? audioSink.audio.muted : false
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property bool audioInputReady: audioSource !== null && audioSource !== undefined && audioSource.ready && audioSource.audio !== null && audioSource.audio !== undefined
    readonly property real inputVolume: audioInputReady ? Math.max(0, Math.min(1, audioSource.audio.volume)) : 0
    readonly property bool inputMuted: audioInputReady ? audioSource.audio.muted : false
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: battery !== null && battery !== undefined && battery.ready
    readonly property int batteryPercent: batteryReady ? Math.round(Math.max(0, Math.min(100, battery.percentage * 100))) : -1
    readonly property bool showTray: root.screen && Quickshell.screens.length > 0 && root.screen === Quickshell.screens[0]
    // The tray is shared across outputs and is rendered on the primary bar.
    readonly property bool batteryCharging: batteryReady && battery.changeRate > 0
    readonly property bool popupVisible: launcherPopup.visible || volumePopup.visible || brightnessPopup.visible || batteryPopup.visible || calendarPopup.visible || notificationPopup.visible || powerPopup.visible
    readonly property string audioIcon: !root.audioReady ? "volume_off" : (root.audioMuted || root.volume <= 0 ? "volume_off" : (root.volume < 0.5 ? "volume_down" : "volume_up"))
    readonly property string batteryIcon: !root.batteryReady ? "battery_unknown" : (root.batteryCharging ? "battery_charging_full" : (root.batteryPercent <= 15 ? "battery_alert" : (root.batteryPercent >= 90 ? "battery_full" : (root.batteryPercent >= 60 ? "battery_6_bar" : (root.batteryPercent >= 30 ? "battery_3_bar" : "battery_1_bar")))))
    readonly property string audioOutputLabel: root.audioNodeLabel(root.audioSink, "Default speakers")
    readonly property string audioInputLabel: root.audioNodeLabel(root.audioSource, "Default microphone")

    function audioNodeLabel(node, fallback) {
        if (!node)
            return fallback;

        var nickname = node.nickname || "";
        var description = node.description || "";
        var name = node.name || "";
        return nickname.length > 0 ? nickname : (description.length > 0 ? description : (name.length > 0 ? name : fallback));
    }

    function toggleLauncher() {
        togglePopup(launcherPopup);
    }

    function toggleNotifications() {
        togglePopup(notificationPopup);
    }

    function openSettings() {
        root.closePopups();
        if (root.settingsWindow) {
            root.settingsWindow.targetScreen = root.screen;
            root.settingsWindow.visible = true;
        }
    }

    function togglePopup(popup) {
        var wasVisible = popup.visible;
        closePopups();
        if (!wasVisible) {
            popup.updatePosition();
            popup.visible = true;
        }
    }

    function closePopups() {
        launcherPopup.visible = false;
        volumePopup.visible = false;
        brightnessPopup.visible = false;
        batteryPopup.visible = false;
        calendarPopup.visible = false;
        notificationPopup.visible = false;
        powerPopup.visible = false;
    }

    function refreshBrightness() {
        brightnessReader.exec(["brightnessctl", "-m"]);
    }

    function updateBrightness(raw) {
        var fields = raw.trim().split(",");
        var value = parseInt((fields[3] || "").replace("%", ""), 10);
        if (!isNaN(value))
            root.brightnessPercent = value;

    }

    function setBrightness(value) {
        var bounded = Math.max(1, Math.min(100, Math.round(value)));
        brightnessSetter.exec(["brightnessctl", "set", bounded + "%"]);
    }

    function refreshWorkspaceState() {
        Hyprland.refreshWorkspaces();
        root.workspaceRevision += 1;
        workspaceRulesReader.exec(["hyprctl", "-j", "workspacerules"]);
    }

    function updatePersistentWorkspaceRules(raw) {
        var parsed;
        try {
            parsed = JSON.parse(raw);
        } catch (error) {
            return ;
        }
        if (!Array.isArray(parsed))
            return ;

        root.persistentWorkspaceRules = parsed.filter(function(rule) {
            var workspaceString = rule && rule.workspaceString !== undefined ? String(rule.workspaceString) : "";
            return rule && rule.enabled !== false && rule.persistent === true && /^-?[0-9]+$/.test(workspaceString);
        });
    }

    function workspaceEntries() {
        var revision = root.workspaceRevision;
        var screenName = root.screen ? root.screen.name : "";
        var actualWorkspaces = Hyprland.workspaces.values.filter(function(workspace) {
            return workspace.monitor && workspace.monitor.name === screenName && (!workspace.name || workspace.name.indexOf("special:") !== 0);
        });
        var entries = [];
        var included = {
        };
        root.persistentWorkspaceRules.forEach(function(rule) {
            if (rule.monitor && rule.monitor !== screenName)
                return ;

            var workspaceId = parseInt(String(rule.workspaceString), 10);
            var workspace = actualWorkspaces.find(function(candidate) {
                return candidate.id === workspaceId;
            });
            entries.push(workspace || {
                "id": workspaceId,
                "name": rule.defaultName || String(rule.workspaceString),
                "active": false,
                "focused": false
            });
            included[workspaceId] = true;
        });
        actualWorkspaces.forEach(function(workspace) {
            if (!included[workspace.id])
                entries.push(workspace);

        });
        entries.sort(function(left, right) {
            return Number(left.id) - Number(right.id);
        });
        return entries;
    }

    function workspaceOccupied(workspaceId) {
        var revision = root.workspaceRevision;
        return Hyprland.toplevels.values.some(function(toplevel) {
            return toplevel.workspace && toplevel.workspace.id === workspaceId;
        });
    }

    function setVolume(value) {
        var bounded = Math.max(0, Math.min(1, value));
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(bounded * 100) + "%"]);
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
    }

    function setInputVolume(value) {
        var bounded = Math.max(0, Math.min(1, value));
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(bounded * 100) + "%"]);
    }

    function toggleInputMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
    }

    Component.onCompleted: {
        root.refreshBrightness();
        root.refreshWorkspaceState();
    }

    PwObjectTracker {
        objects: {
            var nodes = [];
            if (root.audioSink)
                nodes.push(root.audioSink);

            if (root.audioSource && root.audioSource !== root.audioSink)
                nodes.push(root.audioSource);

            return nodes;
        }
    }

    HyprlandFocusGrab {
        id: popupFocusGrab

        windows: [root.barWindow, launcherPopup, volumePopup, brightnessPopup, batteryPopup, calendarPopup, notificationPopup, powerPopup]
        active: root.popupVisible
        onCleared: root.closePopups()
    }

    IdleInhibitor {
        window: root.barWindow
        enabled: root.caffeineEnabled
    }

    Process {
        id: brightnessReader

        stdout: StdioCollector {
            onStreamFinished: root.updateBrightness(this.text)
        }

    }

    Process {
        id: brightnessSetter

        onExited: root.refreshBrightness()
    }

    Process {
        id: workspaceRulesReader

        stdout: StdioCollector {
            onStreamFinished: root.updatePersistentWorkspaceRules(this.text)
        }

    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.refreshBrightness()
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    ScriptModel {
        id: localWorkspaces

        objectProp: "id"
        values: root.screen ? root.workspaceEntries() : []
    }

    Connections {
        function onRawEvent(event) {
            var refreshEvents = ["configreloaded", "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2", "moveworkspace", "moveworkspacev2", "renameworkspace"];
            if (refreshEvents.indexOf(event.name) !== -1)
                root.refreshWorkspaceState();

        }

        target: Hyprland
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.surfaceContainerLow

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePopups()
        }

    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.outlineVariant
    }

    Row {
        id: leftSection

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space8

        BarButton {
            id: launcherButton

            icon: "apps"
            compact: true
            onActivated: root.toggleLauncher()
        }

        Rectangle {
            id: workspaceGroup

            height: 34
            width: workspaceRow.implicitWidth + 12
            radius: Theme.shapeLarge
            color: Theme.surfaceContainerLowest
            border.width: 1
            border.color: Theme.outlineVariant

            Row {
                id: workspaceRow

                anchors.centerIn: parent
                spacing: Theme.space4

                Repeater {
                    model: localWorkspaces

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool occupied: modelData ? root.workspaceOccupied(modelData.id) : false

                        implicitWidth: Math.max(34, workspaceLabel.implicitWidth + 20)
                        height: 28
                        radius: Theme.shapeMedium
                        color: modelData.focused ? Theme.accent : (modelData.active ? Theme.accentSurface : "transparent")
                        border.width: modelData.active && !modelData.focused ? 1 : 0
                        border.color: Theme.outlineVariant

                        Text {
                            id: workspaceLabel

                            anchors.centerIn: parent
                            text: modelData.name && modelData.name.length > 0 ? modelData.name : modelData.id
                            color: modelData.focused ? Theme.onAccent : (parent.occupied ? Theme.accent : Theme.text)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.labelMediumSize
                            font.weight: modelData.focused ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.activate)
                                    modelData.activate();
                                else
                                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })");
                            }
                        }

                    }

                }

            }

        }

    }

    Rectangle {
        id: clockButton

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 116
        height: 32
        radius: Theme.shapeMedium
        color: clockMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
        border.width: clockMouse.containsMouse ? 1 : 0
        border.color: Theme.outlineVariant

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 0

            Text {
                width: parent.width
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyMediumSize
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: Qt.formatDateTime(clock.date, "ddd, d MMM")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSmallSize
                horizontalAlignment: Text.AlignHCenter
            }

        }

        MouseArea {
            id: clockMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.togglePopup(calendarPopup)
        }

    }

    Row {
        id: rightSection

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space4

        BarButton {
            id: audioButton

            icon: root.audioIcon
            label: root.audioReady ? Math.round(root.volume * 100) + "%" : "--"
            active: volumePopup.visible
            onActivated: root.togglePopup(volumePopup)
        }

        BarButton {
            id: brightnessButton

            icon: "brightness_medium"
            label: root.brightnessPercent >= 0 ? root.brightnessPercent + "%" : "--"
            active: brightnessPopup.visible
            onActivated: root.togglePopup(brightnessPopup)
        }

        BarButton {
            id: batteryButton

            icon: root.batteryIcon
            label: root.batteryReady ? root.batteryPercent + "%" : "--"
            destructive: root.batteryReady && root.batteryPercent <= 15 && !root.batteryCharging
            active: batteryPopup.visible
            onActivated: root.togglePopup(batteryPopup)
        }

        BarButton {
            id: notificationButton

            icon: root.notificationService && root.notificationService.doNotDisturb ? "notifications_off" : (root.notificationService && root.notificationService.unreadCount > 0 ? "notifications_active" : "notifications")
            compact: true
            active: notificationPopup.visible || (root.notificationService ? root.notificationService.unreadCount > 0 : false)
            activeColor: root.notificationService && root.notificationService.doNotDisturb ? Theme.warning : Theme.accent
            onActivated: root.togglePopup(notificationPopup)
        }

        Row {
            id: traySection

            width: root.showTray ? implicitWidth : 0
            visible: root.showTray
            spacing: 2

            Repeater {
                model: SystemTray.items

                delegate: TrayItem {
                    required property var modelData

                    trayItem: modelData
                }

            }

        }

        BarButton {
            id: quickSettingsButton

            icon: "tune"
            compact: true
            onActivated: root.togglePopup(powerPopup)
        }

    }

    LauncherPopup {
        id: launcherPopup

        anchorItem: launcherButton
        barWindow: root.barWindow
    }

    VolumePopup {
        id: volumePopup

        anchorItem: audioButton
        barWindow: root.barWindow
        volume: root.volume
        muted: root.audioMuted
        outputAvailable: root.audioReady
        inputVolume: root.inputVolume
        inputMuted: root.inputMuted
        inputAvailable: root.audioInputReady
        outputDescription: root.audioOutputLabel
        inputDescription: root.audioInputLabel
        onRequestVolume: function(value) {
            root.setVolume(value);
        }
        onRequestMute: root.toggleMute()
        onRequestInputVolume: function(value) {
            root.setInputVolume(value);
        }
        onRequestInputMute: root.toggleInputMute()
    }

    BrightnessPopup {
        id: brightnessPopup

        anchorItem: brightnessButton
        barWindow: root.barWindow
        value: root.brightnessPercent
        onRequestValue: function(value) {
            root.setBrightness(value);
        }
    }

    BatteryPopup {
        id: batteryPopup

        anchorItem: batteryButton
        barWindow: root.barWindow
        battery: root.battery
    }

    NotificationPopup {
        id: notificationPopup

        anchorItem: notificationButton
        barWindow: root.barWindow
        notificationService: root.notificationService
    }

    CalendarPopup {
        id: calendarPopup

        anchorItem: clockButton
        barWindow: root.barWindow
        clock: clock
    }

    PowerPopup {
        id: powerPopup

        anchorItem: quickSettingsButton
        barWindow: root.barWindow
        caffeineEnabled: root.caffeineEnabled
        onRequestToggleCaffeine: root.caffeineEnabled = !root.caffeineEnabled
        onRequestSettings: root.openSettings()
    }

}
