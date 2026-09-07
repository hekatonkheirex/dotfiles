import QtQuick

import Quickshell
import Quickshell.Io

import "."

ShellRoot {
    id: root

    property int keyboardBrightnessPercent: -1
    property bool keyboardBrightnessKnown: false

    SettingsStore {
        id: settingsStore
    }

    Component.onCompleted: {
        Theme.settings = settingsStore;
        keyboardBrightnessReader.exec(["brightnessctl", "-m", "-d", "tpacpi::kbd_backlight"]);
    }

    NotificationService {
        id: sharedNotificationService
        settings: settingsStore
    }

    SettingsWindow {
        id: sharedSettingsWindow
        settings: settingsStore
        notificationService: sharedNotificationService
        targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    NotificationToast {
        notificationService: sharedNotificationService
        targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    LockScreen {
        id: lockScreen
    }

    ScreenshotService {
        id: screenshotService
    }

    StatusOsd {
        id: statusOsd
        targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    Variants {
        id: bars
        model: Quickshell.screens

        delegate: Component {
            BarWindow {
                settingsWindow: sharedSettingsWindow
                notificationService: sharedNotificationService
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggleLauncher() {
            for (var index = 0; index < bars.instances.length; index++) {
                bars.instances[index].toggleLauncher();
            }
        }

        function toggleNotifications() {
            for (var index = 0; index < bars.instances.length; index++) {
                bars.instances[index].toggleNotifications();
            }
        }

        function clearNotifications() {
            sharedNotificationService.clearAll();
        }

        function toggleSettings() {
            sharedSettingsWindow.toggle();
        }

        function volumeUp() {
            Quickshell.execDetached([
                "wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"
            ]);
            volumeOsdRefresh.restart();
        }

        function volumeDown() {
            Quickshell.execDetached([
                "wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", "5%-"
            ]);
            volumeOsdRefresh.restart();
        }

        function toggleMute() {
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
            volumeOsdRefresh.restart();
        }

        function brightnessUp() {
            brightnessControl.exec(["brightnessctl", "set", "5%+"]);
        }

        function brightnessDown() {
            brightnessControl.exec(["brightnessctl", "set", "5%-"]);
        }

        function keyboardBrightnessUp() {
            keyboardBrightnessControl.exec(["brightnessctl", "-d", "tpacpi::kbd_backlight", "set", "+1"]);
        }

        function keyboardBrightnessDown() {
            keyboardBrightnessControl.exec(["brightnessctl", "-d", "tpacpi::kbd_backlight", "set", "1-"]);
        }

        function keyboardBrightnessToggle() {
            var target = root.keyboardBrightnessPercent > 0 ? "0%" : "100%";
            keyboardBrightnessControl.exec(["brightnessctl", "-d", "tpacpi::kbd_backlight", "set", target]);
        }

        function screenshotRegion() {
            screenshotService.captureRegion();
        }

        function screenshotFullscreen() {
            screenshotService.captureFullscreen();
        }

    }

    function refreshBarBrightness() {
        for (var index = 0; index < bars.instances.length; index++) {
            bars.instances[index].refreshBrightness();
        }
    }

    function updateVolumeOsd(raw) {
        var match = raw.match(/Volume:\s+([0-9.]+)/);
        if (!match) {
            return;
        }

        statusOsd.showVolume(
            parseFloat(match[1]) * 100,
            raw.indexOf("[MUTED]") !== -1
        );
    }

    function updateBrightnessOsd(raw) {
        var fields = raw.trim().split(",");
        var value = parseInt((fields[3] || "").replace("%", ""), 10);
        if (!isNaN(value)) {
            statusOsd.showBrightness(value);
            root.refreshBarBrightness();
        }
    }

    function updateKeyboardBrightnessOsd(raw) {
        var fields = raw.trim().split(",");
        var value = parseInt((fields[3] || "").replace("%", ""), 10);
        if (!isNaN(value)) {
            var changed = root.keyboardBrightnessKnown && root.keyboardBrightnessPercent !== value;
            root.keyboardBrightnessPercent = value;
            root.keyboardBrightnessKnown = true;
            if (changed)
                statusOsd.showKeyboardBrightness(value);

        }

    }

    Timer {
        id: volumeOsdRefresh
        interval: 120
        repeat: false
        onTriggered: volumeReader.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    }

    // Firmware-handled Fn keys can change the LED without producing a
    // compositor key event. Poll the device so those changes still get an OSD.
    Timer {
        id: keyboardBrightnessPoll
        interval: 500
        repeat: true
        running: true
        onTriggered: keyboardBrightnessPoller.exec(["brightnessctl", "-m", "-d", "tpacpi::kbd_backlight"])
    }

    Process {
        id: volumeReader
        stdout: StdioCollector {
            onStreamFinished: root.updateVolumeOsd(this.text)
        }
    }

    Process {
        id: brightnessControl
        onExited: brightnessReader.exec(["brightnessctl", "-m"])
    }

    Process {
        id: brightnessReader
        stdout: StdioCollector {
            onStreamFinished: root.updateBrightnessOsd(this.text)
        }
    }

    Process {
        id: keyboardBrightnessControl
        onExited: keyboardBrightnessReader.exec(["brightnessctl", "-m", "-d", "tpacpi::kbd_backlight"])
    }

    Process {
        id: keyboardBrightnessReader
        stdout: StdioCollector {
            onStreamFinished: root.updateKeyboardBrightnessOsd(this.text)
        }
    }

    Process {
        id: keyboardBrightnessPoller
        stdout: StdioCollector {
            onStreamFinished: root.updateKeyboardBrightnessOsd(this.text)
        }
    }

    IpcHandler {
        target: "session"

        function lock() {
            lockScreen.lock();
        }
    }
}
