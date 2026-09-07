import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property var settings
    readonly property string defaultDirectory: {
        var home = Quickshell.env("HOME");
        return (home && home.length > 0 ? home : "/") + "/Pictures/Walls";
    }
    readonly property string configHome: {
        var value = Quickshell.env("XDG_CONFIG_HOME");
        return value && value.length > 0 ? value : (Quickshell.env("HOME") || "") + "/.config";
    }
    readonly property string cacheHome: {
        var value = Quickshell.env("XDG_CACHE_HOME");
        return value && value.length > 0 ? value : (Quickshell.env("HOME") || "") + "/.cache";
    }
    readonly property string paletteRefreshScript: root.configHome + "/quickshell/scripts/refresh-wallpaper-palette.sh"
    readonly property string wallpaperStateFile: root.cacheHome + "/quickshell/current-wallpaper"
    readonly property string directory: settings && settings.wallpaperDirectory.length > 0
        ? settings.wallpaperDirectory
        : root.defaultDirectory
    readonly property string transitionType: settings ? settings.wallpaperTransition : "fade"
    readonly property int transitionStep: settings ? settings.wallpaperTransitionStep : 90
    readonly property real transitionDuration: settings ? settings.wallpaperTransitionDuration : 1.0
    readonly property int transitionFps: settings ? settings.wallpaperTransitionFps : 30

    property alias files: wallpaperFiles
    property bool daemonAvailable: false
    property string currentPath: ""
    property string statusMessage: ""
    property int currentIndex: -1
    property string pendingPath: ""
    property bool pendingRestore: false
    property bool daemonStartAttempted: false

    signal status(string message)

    function setStatus(message) {
        root.statusMessage = message;
        root.status(message);
    }

    function refresh() {
        root.refreshFiles();
        root.checkDaemon();
    }

    function restoreSavedWallpaper() {
        restoreReader.exec(["cat", root.wallpaperStateFile]);
    }

    function updateRestoredWallpaper(output) {
        var path = output.trim();
        if (!path) {
            return;
        }

        root.pendingPath = path;
        root.currentPath = path;
        root.pendingRestore = true;
        if (root.daemonAvailable) {
            root.applyPending();
        } else {
            root.checkDaemon();
        }
    }

    function refreshFiles() {
        wallpaperFiles.clear();
        if (!root.directory || root.directory.length === 0) {
            root.setStatus("Choose a wallpaper directory");
            return;
        }
        fileReader.exec(["find", root.directory, "-maxdepth", "1", "-type", "f", "-print"]);
    }

    function updateFiles(output) {
        var paths = output.split("\n").filter(function(path) {
            var lower = path.trim().toLowerCase();
            return lower.length > 0
                && (lower.endsWith(".jpg") || lower.endsWith(".jpeg")
                    || lower.endsWith(".png") || lower.endsWith(".webp")
                    || lower.endsWith(".gif") || lower.endsWith(".bmp")
                    || lower.endsWith(".tiff") || lower.endsWith(".tif")
                    || lower.endsWith(".avif"));
        });
        paths.sort();

        wallpaperFiles.clear();
        for (var index = 0; index < paths.length; index++) {
            var path = paths[index].trim();
            wallpaperFiles.append({
                path: path,
                name: path.substring(path.lastIndexOf("/") + 1)
            });
        }

        if (paths.length === 0) {
            root.setStatus("No image files found");
        }
    }

    function checkDaemon() {
        daemonProbe.exec(["awww", "query"]);
    }

    function apply(path) {
        if (!path || path.length === 0) {
            return;
        }

        root.pendingPath = path;
        root.currentPath = path;
        root.pendingRestore = false;
        if (!root.daemonAvailable) {
            root.ensureDaemon();
            return;
        }
        root.applyPending();
    }

    function applyPending() {
        if (!root.pendingPath || root.pendingPath.length === 0) {
            return;
        }

        var command = [
            "awww", "img",
            "--resize", "crop",
            "--transition-type", root.transitionType,
            "--transition-step", String(root.transitionStep),
            "--transition-duration", root.transitionDuration.toFixed(2),
            "--transition-fps", String(root.transitionFps),
            root.pendingPath
        ];
        imageSetter.exec(command);
    }

    function ensureDaemon() {
        if (root.daemonStartAttempted) {
            return;
        }
        root.daemonStartAttempted = true;
        Quickshell.execDetached(["/usr/bin/systemctl", "--user", "start", "awww-daemon.service"]);
        daemonRetry.restart();
        root.setStatus("Starting awww daemon");
    }

    function select(index) {
        if (index < 0 || index >= wallpaperFiles.count) {
            return;
        }
        root.currentIndex = index;
        root.apply(wallpaperFiles.get(index).path);
    }

    function next() {
        if (wallpaperFiles.count > 0) {
            root.select((root.currentIndex + 1 + wallpaperFiles.count) % wallpaperFiles.count);
        }
    }

    function previous() {
        if (wallpaperFiles.count > 0) {
            root.select((root.currentIndex - 1 + wallpaperFiles.count) % wallpaperFiles.count);
        }
    }

    function random() {
        if (wallpaperFiles.count > 0) {
            root.select(Math.floor(Math.random() * wallpaperFiles.count));
        }
    }

    ListModel {
        id: wallpaperFiles
    }

    Process {
        id: restoreReader

        stdout: StdioCollector {
            onStreamFinished: root.updateRestoredWallpaper(this.text)
        }
    }

    Process {
        id: fileReader

        stdout: StdioCollector {
            onStreamFinished: root.updateFiles(this.text)
        }
    }

    Process {
        id: daemonProbe

        onExited: function(exitCode) {
            root.daemonAvailable = exitCode === 0;
            if (root.daemonAvailable) {
                root.daemonStartAttempted = false;
                if (root.pendingPath.length > 0) {
                    root.applyPending();
                }
            } else {
                root.ensureDaemon();
            }
        }
    }

    Process {
        id: imageSetter

        onExited: function(exitCode) {
            var restoring = root.pendingRestore;
            root.pendingRestore = false;

            if (exitCode === 0) {
                if (!restoring) {
                    root.setStatus("Wallpaper applied");
                    paletteRefresh.exec([root.paletteRefreshScript, root.currentPath]);
                }
            } else {
                root.daemonAvailable = false;
                if (!restoring) {
                    root.setStatus("awww could not apply the wallpaper");
                } else {
                    console.warn("[wallpaper] could not restore the saved wallpaper");
                }
            }
            root.pendingPath = "";
        }
    }

    Process {
        id: paletteRefresh

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("[wallpaper] palette refresh failed", exitCode);
            }
        }
    }

    Timer {
        id: daemonRetry
        interval: 650
        repeat: false
        onTriggered: root.checkDaemon()
    }

    Component.onCompleted: {
        root.refreshFiles();
        root.checkDaemon();
        root.restoreSavedWallpaper();
    }
}
