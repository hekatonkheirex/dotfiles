pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Single owner of the niri event-stream for this config. Workspace list,
 * focused output, and fullscreen state all derive from here so every pill
 * surface reads one shared, debounced source instead of spinning its own
 * niri msg processes.
 *
 * niri's IPC has no is_fullscreen field (verified against the running 26.04
 * instance across windows/focused-window/event-stream). fullscreenByOutput
 * is inferred by comparing each output's focused window size to that
 * output's logical size — a heuristic, not an exact flag.
 */
QtObject {
    id: root

    readonly property string socketDiscovery: "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1)"

    property var workspaces: []
    property string focusedOutput: ""
    onFocusedOutputChanged: root.recomputeFullscreen()
    property var fullscreenByOutput: ({})

    function focusWorkspace(idx) {
        Quickshell.execDetached(["sh", "-c", root.socketDiscovery + " niri msg action focus-workspace " + idx])
    }

    function scrollWorkspace(deltaY) {
        var action = deltaY > 0 ? "focus-workspace-up" : "focus-workspace-down"
        Quickshell.execDetached(["sh", "-c", root.socketDiscovery + " niri msg action " + action])
    }

    property var workspacesQuery: Process {
        command: ["sh", "-c", root.socketDiscovery + " niri msg -j workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    var list = []
                    for (var i = 0; i < data.length; i++) {
                        list.push({
                            id: data[i].id,
                            idx: data[i].idx,
                            output: data[i].output || "",
                            isFocused: !!data[i].is_focused,
                            isOccupied: data[i].active_window_id != null
                        })
                    }
                    list.sort(function(a, b) { return a.idx - b.idx })
                    root.workspaces = list
                } catch (e) {
                    print("Niri: workspaces parse error:", e)
                }
            }
        }
    }

    property var focusedOutputQuery: Process {
        id: focusedOutputQuery
        command: ["sh", "-c", root.socketDiscovery + " niri msg -j focused-output"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    root.focusedOutput = (data && typeof data.name === "string") ? data.name : ""
                } catch (e) {
                    root.focusedOutput = ""
                }
            }
        }
    }

    /** windowsQuery + outputsQuery jointly compute fullscreenByOutput. */
    property var windowsQuery: Process {
        id: windowsQuery
        command: ["sh", "-c", root.socketDiscovery + " niri msg -j windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.lastWindows = JSON.parse(text.trim())
                    root.recomputeFullscreen()
                } catch (e) {
                    print("Niri: windows parse error:", e)
                }
            }
        }
    }

    property var outputsQuery: Process {
        id: outputsQuery
        command: ["sh", "-c", root.socketDiscovery + " niri msg -j outputs"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.lastOutputs = JSON.parse(text.trim())
                    root.recomputeFullscreen()
                } catch (e) {
                    print("Niri: outputs parse error:", e)
                }
            }
        }
    }

    property var lastWindows: []
    property var lastOutputs: ({})

    function recomputeFullscreen() {
        var result = {}
        for (var outName in root.lastOutputs) {
            var out = root.lastOutputs[outName]
            var logical = out && out.logical ? out.logical : null
            result[outName] = false
            if (!logical) continue
            for (var i = 0; i < root.lastWindows.length; i++) {
                var w = root.lastWindows[i]
                if (!w.is_focused || !w.layout || !w.layout.window_size) continue
                // is_focused is global (the one focused window across all
                // outputs); only count it toward the output it actually
                // reports as focused via focusedOutput.
                if (outName !== root.focusedOutput) continue
                var ws = w.layout.window_size
                if (ws[0] === logical.width && ws[1] === logical.height) {
                    result[outName] = true
                }
            }
        }
        root.fullscreenByOutput = result
    }

    function refresh() {
        workspacesQuery.running = true
        focusedOutputQuery.running = true
        windowsQuery.running = true
        outputsQuery.running = true
    }

    property var refreshDebounce: Timer {
        interval: 80
        repeat: false
        onTriggered: root.refresh()
    }

    property var eventStream: Process {
        id: eventStream
        command: ["sh", "-c", root.socketDiscovery + " niri msg event-stream"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                root.refreshDebounce.restart()
            }
        }
        onRunningChanged: {
            if (!running) eventStreamRetry.start()
        }
    }

    property var eventStreamRetry: Timer {
        interval: 1000
        onTriggered: eventStream.running = true
    }

    Component.onCompleted: root.refresh()
}
