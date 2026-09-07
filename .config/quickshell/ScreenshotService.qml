import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string screenshotDirectory: (Quickshell.env("HOME") || "/tmp") + "/Pictures/Screenshots"
    property bool busy: false
    property bool regionMode: false
    property string pendingPath: ""

    function pad(value, length) {
        var text = String(value);
        while (text.length < length)
            text = "0" + text;

        return text;
    }

    function nextPath() {
        var now = new Date();
        var timestamp = now.getFullYear() + "-" + root.pad(now.getMonth() + 1, 2) + "-" + root.pad(now.getDate(), 2) + "_" + root.pad(now.getHours(), 2) + "-" + root.pad(now.getMinutes(), 2) + "-" + root.pad(now.getSeconds(), 2) + "-" + root.pad(now.getMilliseconds(), 3);
        return root.screenshotDirectory + "/Screenshot-" + timestamp + ".png";
    }

    function captureRegion() {
        root.start(true);
    }

    function captureFullscreen() {
        root.start(false);
    }

    function start(region) {
        if (root.busy)
            return ;

        root.busy = true;
        root.regionMode = region;
        root.pendingPath = root.nextPath();
        directoryProcess.exec(["mkdir", "-p", root.screenshotDirectory]);
    }

    function finish() {
        root.busy = false;
        root.regionMode = false;
        root.pendingPath = "";
    }

    function saveRegion(geometry) {
        if (!geometry || geometry.length === 0) {
            root.finish();
            return ;
        }
        screenshotProcess.exec(["grim", "-g", geometry, root.pendingPath]);
    }

    function saveFullscreen() {
        screenshotProcess.exec(["grim", root.pendingPath]);
    }

    function copyPendingScreenshot() {
        clipboardProcess.exec(["sh", "-c", "exec wl-copy --type image/png < \"$1\"", "quickshell-screenshot-clipboard", root.pendingPath]);
    }

    Process {
        id: directoryProcess

        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.finish();
            else if (root.regionMode)
                // Quickshell gives child processes a live stdin pipe. Close it
                // before launching slurp so it can create its Wayland overlay
                // instead of waiting on that pipe.
                regionProcess.exec(["sh", "-c", "exec slurp </dev/null"]);
            else
                root.saveFullscreen();
        }
    }

    Process {
        id: regionProcess

        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.finish();

        }

        stdout: StdioCollector {
            onStreamFinished: root.saveRegion(this.text.trim())
        }

    }

    Process {
        id: screenshotProcess

        onExited: function(exitCode) {
            if (exitCode === 0)
                root.copyPendingScreenshot();
            else
                root.finish();
        }
    }

    Process {
        id: clipboardProcess

        onExited: root.finish()
    }

}
