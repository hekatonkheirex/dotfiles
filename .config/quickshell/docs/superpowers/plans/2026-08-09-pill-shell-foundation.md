# Pill Shell Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a working Ukishima-style morphing pill shell for Niri — one pill per monitor that expands in place and hosts a real surface (the audio mixer) grown inside it — as a self-contained `pill/` config launched via `qs -c pill`, fully independent of the existing `bar/`/`config/` shell.

**Architecture:** Two `PanelWindow`s per monitor (`reserve` claims the exclusive zone, `overlay` hosts the single `Pill` item). `Pill.qml` is one `Item` whose size is state-driven (`rest` / `hover` / `surface open`) with a ported Ukishima morph easing curve. Workspace/fullscreen state comes from a new `Niri` singleton that owns the `niri msg event-stream` process (replacing the copy embedded in `bar/WorkspaceIndicator.qml` for this config). The mixer surface is ported from `bar/AudioPopup.qml`'s content, proving the "surface grows inside the pill, cross-fades in, Escape/click-outside dismisses" pattern end to end.

**Tech Stack:** QML / Quickshell 0.3.0, existing `bar/SliderControl.qml`, `bar/SwitchControl.qml`, `bar/PopupDivider.qml` primitives (reused via relative import, not duplicated), existing `config/Colors.qml` / `config/Settings.qml` singletons (reused via relative import), `niri msg` CLI + JSON IPC (compositor confirmed: niri 26.04, no native Quickshell module).

## Global Constraints

- This is Plan 1 of a multi-plan build (see `docs/superpowers/specs/2026-08-09-ukishima-pill-shell-design.md`). Remaining surfaces (Battery, Wifi, Bluetooth, Brightness, Launcher, Power, Notification, Calendar, Menu/CommandCenter) are separate follow-up plans, each reusing the exact pattern this plan establishes for the mixer surface. Do not add them here.
- `pill/` is a new, self-contained directory at the repo root (sibling to `bar/`, `config/`). Nothing in `bar/` or `config/` is modified by this plan — the existing default shell (`qs` with no `-c` flag) must keep working unchanged throughout.
- Niri's IPC has **no `is_fullscreen` field** (verified live against the running 26.04 instance — confirmed absent from `windows`, `focused-window`, and every `event-stream` payload, including mid-toggle). Fullscreen is inferred by comparing a monitor's focused window's `layout.window_size` to that output's logical `width`/`height` from `niri msg -j outputs`. This is a heuristic with a known false-positive case (a maximized-but-not-fullscreen window at exactly output size) — do not present it as exact.
- Reuse existing primitives via relative import (`../../bar/SliderControl.qml` etc.) rather than forking copies into `pill/components/` — `SliderControl`, `SwitchControl`, `PopupDivider` are unmodified and already correct.
- Reuse `config/Colors.qml` and `config/Settings.qml` via relative import (`../config/Colors.qml`) for the Matugen/M3 palette and `reduceMotion` — do not build a parallel palette or settings system.
- No animation/easing constants are invented. The morph duration and cubic-bezier curve are ported verbatim from Ukishima's `Singletons/Motion.qml` (`morph: 420`, `easeMorph: Easing.BezierSpline`, `morphCurve: [0.16, 1, 0.3, 1, 1, 1]`), scaled by `Settings.reduceMotion` the same way `Config.qml` already scales its own motion constants.
- No automated QML test framework exists in this repo (confirmed during spec work). Verification is manual/soak: launch `qs -c pill`, inspect stderr for QML errors, exercise the behavior, matching how the rest of this shell is validated (see `bar/WorkspaceIndicator.qml`'s own niri-event-stream pattern, which has no test suite either).
- Every `Process` that shells to `niri msg` must use the same socket-discovery one-liner already proven in `bar/WorkspaceIndicator.qml`: `NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg ...` — do not assume `$NIRI_SOCKET` is already exported.

---

### Task 1: Scaffold `pill/` and port the Motion easing singleton

**Files:**
- Create: `pill/qmldir`
- Create: `pill/Singletons/qmldir`
- Create: `pill/Singletons/Motion.qml`

**Interfaces:**
- Produces: `Motion.morph` (int, ms), `Motion.easeMorph` (int, `Easing.BezierSpline`), `Motion.morphCurve` (`var`, 6-element bezier array), `Motion.fast` (int, ms), `Motion.standard` (int, ms) — consumed by `Pill.qml` in Task 5 for the `Behavior on width/height`.

- [ ] **Step 1: Create the config directory and top-level `qmldir`**

```bash
mkdir -p pill/Singletons pill/components pill/surfaces
```

`pill/qmldir`:
```
module pill
```

- [ ] **Step 2: Write the Motion singleton**

`pill/Singletons/Motion.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell
import "../../config"

QtObject {
    readonly property real mult: Settings.reduceMotion ? 0.4 : 1
    readonly property int fast: Math.round(140 * mult)
    readonly property int standard: Math.round(300 * mult)
    readonly property int morph: Math.round(420 * mult)
    readonly property int easeMorph: Easing.BezierSpline
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
}
```

`pill/Singletons/qmldir`:
```
singleton Motion 1.0 Motion.qml
```

- [ ] **Step 3: Verify it loads standalone**

Run:
```bash
qs -c pill 2>&1 | head -20
```
Expected: an error that `shell.qml` doesn't exist yet in `pill/` (there is no shell entry point until Task 5) — NOT a syntax error inside `Motion.qml` or `qmldir`. If the error mentions `Motion.qml` or `qmldir` syntax, fix before continuing. Then stop the process (`Ctrl-C` / it will have already exited).

- [ ] **Step 4: Commit**

```bash
yadm add pill/qmldir pill/Singletons/qmldir pill/Singletons/Motion.qml
yadm commit -m "Scaffold pill/ config and port Ukishima's morph easing curve"
```

---

### Task 2: `Niri` singleton — event-stream, workspaces, focused window/output, fullscreen heuristic

**Files:**
- Create: `pill/Singletons/Niri.qml`
- Modify: `pill/Singletons/qmldir`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `Niri.workspaces`: `var` (array of `{ id, idx, output, isFocused, isOccupied }`, sorted by `idx`) — consumed by `WorkspaceDots.qml` in Task 3.
  - `Niri.focusedOutput`: `string` (output name, e.g. `"eDP-1"`, or `""`) — consumed by `shell.qml` in Task 5 to resolve the empty-monitor-argument IPC calls.
  - `Niri.fullscreenByOutput`: `var` (object keyed by output name → `bool`) — consumed by `shell.qml` in Task 5 to retract the pill.
  - `function Niri.focusWorkspace(idx)`, `function Niri.scrollWorkspace(deltaY)` — consumed by `WorkspaceDots.qml` in Task 3.

- [ ] **Step 1: Write the Niri singleton**

`pill/Singletons/Niri.qml`:
```qml
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
```

- [ ] **Step 2: Register it in the singletons `qmldir`**

`pill/Singletons/qmldir` (append):
```
singleton Niri 1.0 Niri.qml
```

- [ ] **Step 3: Verify the event-stream process actually starts and parses**

Run:
```bash
sh -c 'NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j workspaces' | python3 -m json.tool | head -5
```
Expected: valid JSON array — confirms the exact command the singleton runs is correct on this machine before wiring it into QML (Task 5 does the actual QML-level verification once `shell.qml` exists to host the singleton).

- [ ] **Step 4: Commit**

```bash
yadm add pill/Singletons/Niri.qml pill/Singletons/qmldir
yadm commit -m "Add Niri singleton: shared event-stream, workspaces, and fullscreen heuristic"
```

---

### Task 3: `WorkspaceDots` component

**Files:**
- Create: `pill/components/WorkspaceDots.qml`

**Interfaces:**
- Consumes: `Niri.workspaces` (Task 2), `Niri.focusWorkspace(idx)`, `Niri.scrollWorkspace(deltaY)`, `Colors.primary` / `Colors.surfaceContainerHighest` / `Colors.outline` / `Colors.fgPrimary` / `Colors.fgSurface` / `Colors.hoverOverlay` (existing `config/Colors.qml`).
- Produces: a `Row` item with `implicitWidth`/`implicitHeight` — consumed by `Pill.qml` in Task 5 as the rest-state content.

- [ ] **Step 1: Write the component**

`pill/components/WorkspaceDots.qml` (ported from `bar/WorkspaceIndicator.qml`'s delegate, horizontal-only since the pill is always a horizontal top bar, and reading from the shared `Niri` singleton instead of owning its own process):

```qml
import QtQuick
import "../Singletons"
import "../../config"

Row {
    id: root
    spacing: 6

    Repeater {
        model: Niri.workspaces

        delegate: Item {
            id: delegateItem
            required property var modelData

            readonly property bool active: modelData.isFocused || wsMouse.containsMouse

            width: active ? 28 : 14
            height: 14

            Behavior on width {
                NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: delegateItem.active ? 14 : (modelData.isOccupied ? 8 : 6)
                radius: height / 2

                color: {
                    if (modelData.isFocused) return Colors.primary
                    var base = modelData.isOccupied ? Colors.surfaceContainerHighest : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)
                    return Qt.tint(base, wsMouse.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
                }

                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Behavior on height { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.idx.toString()
                    opacity: delegateItem.active ? 1.0 : 0.0
                    visible: opacity > 0
                    color: modelData.isFocused ? Colors.fgPrimary : Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.weight: modelData.isFocused ? Font.Bold : Font.Normal
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(delegateItem.modelData.idx)
                onWheel: function(wheel) {
                    wheel.accepted = true
                    Niri.scrollWorkspace(wheel.angleDelta.y)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify it's syntactically sound**

There's no host to render it in yet (that's Task 5) — sanity-check via the QML linter Quickshell ships with:
```bash
qmllint pill/components/WorkspaceDots.qml 2>&1 | grep -v "is not a type\|Unknown module"
```
Expected: no output, or only warnings about the `Singletons`/`config` module imports not being resolvable outside a running Quickshell instance (those are expected and get validated for real in Task 5).

- [ ] **Step 3: Commit**

```bash
yadm add pill/components/WorkspaceDots.qml
yadm commit -m "Port workspace-dots rendering into a Niri-singleton-backed component"
```

---

### Task 4: `AudioSurface` — the ported mixer content

**Files:**
- Create: `pill/surfaces/AudioSurface.qml`

**Interfaces:**
- Consumes: `config/Colors.qml`, `config/Config.qml`, `config/Settings.qml`, `../../bar/SliderControl.qml`, `../../bar/SwitchControl.qml`, `../../bar/PopupDivider.qml` (all existing, unmodified).
- Produces: an `Item` with `implicitHeight` set — consumed by `Pill.qml` in Task 5 as the `surface === "mixer"` content, cross-faded in.

- [ ] **Step 1: Write the surface**

`pill/surfaces/AudioSurface.qml` (content ported from `bar/AudioPopup.qml`'s `contentColumn`, with the `PopupBase` window chrome — layer-shell window, entry transform, its own background rectangle — stripped out, since the pill itself supplies the shape and the cross-fade):

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../bar"
import "../../config"

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight + 32

    property real volume: 0.5
    property bool muted: false
    property real micVolume: 0.5
    property bool micMuted: false

    function setVolume(val) {
        root.volume = Math.max(0, Math.min(1, val))
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.volume)])
    }

    function toggleMute() {
        root.muted = !root.muted
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"])
    }

    function setMicVolume(val) {
        root.micVolume = Math.max(0, Math.min(1, val))
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(root.micVolume)])
    }

    function toggleMicMute() {
        root.micMuted = !root.micMuted
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.micMuted ? "1" : "0"])
    }

    Process {
        id: audioQuery
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                var m = /Volume:\s*([\d.]+)/.exec(out)
                if (m) root.volume = parseFloat(m[1])
                root.muted = out.indexOf("[MUTED]") >= 0
            }
        }
    }

    Process {
        id: micQuery
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                var m = /Volume:\s*([\d.]+)/.exec(out)
                if (m) root.micVolume = parseFloat(m[1])
                root.micMuted = out.indexOf("[MUTED]") >= 0
            }
        }
    }

    function pollAudio() { audioQuery.running = true; micQuery.running = true }

    Process {
        id: audioWatcher
        command: ["pactl", "subscribe"]
        running: root.visible
        stdout: SplitParser {
            onRead: function(data) {
                if (data.indexOf("sink") >= 0 || data.indexOf("source") >= 0) root.pollAudio()
            }
        }
        onRunningChanged: {
            if (!running && root.visible) audioWatcherRetry.start()
        }
    }

    Timer {
        id: audioWatcherRetry
        interval: 1000
        onTriggered: {
            if (root.visible) audioWatcher.running = true
        }
    }

    onVisibleChanged: if (visible) root.pollAudio()
    Component.onCompleted: if (root.visible) root.pollAudio()

    Column {
        id: contentColumn
        anchors {
            fill: parent
            margins: Config.popupPadding
        }
        spacing: 16

        Item {
            width: parent.width
            height: 32

            Text {
                text: "Volume"
                color: Colors.fgSurface
                font.family: Config.fontFamily
                font.pixelSize: Config.fontPixelSize + 8
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }

            SwitchControl {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: !root.muted
                activeColor: Colors.primary
                surfaceContainerHigh: Colors.surfaceContainerHigh
                surfaceContainerHighest: Colors.surfaceContainerHighest
                outline: Colors.outline
                motionDuration: Config.motionMedium
                reducedMotion: Config.reducedMotion
                accessibleName: "Volume enabled"
                onToggled: root.toggleMute()
            }
        }

        PopupDivider {}

        Text {
            text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
            color: root.muted ? Colors.error : Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 4
        }

        SliderControl {
            value: root.volume
            muted: root.muted
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Volume"
            accessibleDescription: "Adjust output volume"
            onChanged: function(val) { root.setVolume(val) }
        }

        PopupDivider {}

        Item {
            width: parent.width
            height: 32

            Text {
                text: "Microphone"
                color: Colors.fgSurface
                font.family: Config.fontFamily
                font.pixelSize: Config.fontPixelSize + 8
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }

            SwitchControl {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: !root.micMuted
                activeColor: Colors.primary
                surfaceContainerHigh: Colors.surfaceContainerHigh
                surfaceContainerHighest: Colors.surfaceContainerHighest
                outline: Colors.outline
                motionDuration: Config.motionMedium
                reducedMotion: Config.reducedMotion
                accessibleName: "Microphone enabled"
                onToggled: root.toggleMicMute()
            }
        }

        Text {
            text: root.micMuted ? "Muted" : Math.round(root.micVolume * 100) + "%"
            color: root.micMuted ? Colors.error : Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 4
        }

        SliderControl {
            value: root.micVolume
            muted: root.micMuted
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Microphone volume"
            accessibleDescription: "Adjust microphone volume"
            onChanged: function(val) { root.setMicVolume(val) }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
yadm add pill/surfaces/AudioSurface.qml
yadm commit -m "Port the mixer popup content into a pill-hosted AudioSurface"
```

---

### Task 5: `Pill.qml` — the morphing pill body

**Files:**
- Create: `pill/Pill.qml`

**Interfaces:**
- Consumes: `Motion.morph`/`easeMorph`/`morphCurve` (Task 1), `WorkspaceDots` (Task 3), `AudioSurface` (Task 4), `Colors.surfaceContainerHigh`/`Colors.outlineVariant` (existing).
- Produces:
  - `property real s` (per-monitor scale factor, set by the host window)
  - `property string surface` (bound from the host; `""` when nothing is open, `"mixer"` when the audio surface is showing)
  - `property bool hovered`, `property bool pinned` — read by the host window in Task 6 to decide the input mask
  - `signal requestSurface(string name)` — emitted on the clock/tray-equivalent click targets (only the workspace-dots-adjacent mixer icon exists this task) so the host can call `toggleSurface`
  - `signal requestClose()` — emitted on Escape / outside click forwarded from the host
  - `readonly property real restWidth`, `readonly property real restHeight` — read by the host for the reserve strip's exclusive zone

- [ ] **Step 1: Write `Pill.qml`**

`pill/Pill.qml`:
```qml
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
                    text: "" // volume_up, Material Symbols
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
```

- [ ] **Step 2: Commit**

```bash
yadm add pill/Pill.qml
yadm commit -m "Add Pill.qml: morphing body hosting workspace dots and the mixer surface"
```

---

### Task 6: `shell.qml` — per-monitor windows, mask, fullscreen retract, IPC

**Files:**
- Create: `pill/shell.qml`

**Interfaces:**
- Consumes: `Pill.qml` (Task 5), `Niri.focusedOutput`/`Niri.fullscreenByOutput` (Task 2).
- Produces: the `qs -c pill` entry point. `IpcHandler { target: "pill" }` with `mixer(mon)` and `hide()` handlers — consumed by Task 7's `niri.kdl` keybinds.

- [ ] **Step 1: Write `shell.qml`**

`pill/shell.qml`:
```qml
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Singletons"

ShellRoot {
    id: root

    property string openMon: ""
    property string openSurface: ""

    function toggleSurface(mon, surface) {
        if (!mon || mon.length === 0) mon = Niri.focusedOutput
        if (root.openMon === mon && root.openSurface === surface) {
            root.close()
            return
        }
        root.openMon = mon
        root.openSurface = surface
    }

    function close() {
        root.openMon = ""
        root.openSurface = ""
    }

    IpcHandler {
        target: "pill"
        function mixer(mon: string): void { root.toggleSurface(mon, "mixer") }
        function hide(): void { root.close() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserve
            required property var modelData
            readonly property real topGap: 8
            readonly property real restHeight: 38

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: restHeight + topGap
            aboveWindows: true

            anchors { top: true; left: true; right: true }
            implicitHeight: restHeight + topGap

            mask: Region {}
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property real topGap: 8
            readonly property string surfaceName: root.openMon === modelData.name ? root.openSurface : ""
            readonly property bool surfaceOpen: surfaceName.length > 0
            readonly property bool modal: surfaceOpen || pill.held
            readonly property bool monFullscreen: !!Niri.fullscreenByOutput[modelData.name]

            onMonFullscreenChanged: if (monFullscreen && root.openMon === modelData.name) root.close()

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: surfaceOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "pill"

            anchors { top: true; left: true; right: true; bottom: true }

            mask: monFullscreen ? hiddenRegion : (modal ? fullRegion : pillRegion)
            Region { id: hiddenRegion }
            Region {
                id: pillRegion
                x: pill.x
                y: pill.y
                width: pill.width
                height: pill.height
            }
            Region {
                id: fullRegion
                width: overlay.width
                height: overlay.height
            }

            MouseArea {
                anchors.fill: parent
                enabled: overlay.modal
                onPressed: (mouse) => {
                    var inside = mouse.x >= pillRegion.x && mouse.x <= pillRegion.x + pillRegion.width
                        && mouse.y >= pillRegion.y && mouse.y <= pillRegion.y + pillRegion.height
                    if (!inside) root.close()
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: overlay.surfaceOpen

                Keys.onEscapePressed: root.close()

                Pill {
                    id: pill
                    anchors.top: parent.top
                    anchors.topMargin: overlay.topGap
                    anchors.horizontalCenter: parent.horizontalCenter
                    surface: overlay.surfaceName
                    opacity: overlay.monFullscreen ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.morph; easing.type: Easing.OutCubic }
                    }

                    onRequestSurface: (name) => root.toggleSurface(overlay.modelData.name, name)
                    onRequestClose: root.close()
                }
            }

            onSurfaceOpenChanged: if (surfaceOpen) focusScope.forceActiveFocus()
        }
    }
}
```

- [ ] **Step 2: Launch it and verify no QML errors**

```bash
pkill -f "qs -c pill" 2>/dev/null
qs -c pill > /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/pill.log 2>&1 &
sleep 2
grep -iE "error|fail|warning" /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/pill.log
pgrep -f "qs -c pill"
```
Expected: no `error`/`fail` lines (warnings about missing icon font glyphs are acceptable if the Material Symbols font isn't in the sandbox, but not QML property/type errors), and `pgrep` prints a PID.

- [ ] **Step 3: Manually verify the pill on screen**

With `qs -c pill` still running: confirm a pill-shaped bar appears top-center, showing workspace dots and a volume icon; hovering/clicking the volume icon morphs it into the mixer surface with working sliders; clicking outside or pressing Escape closes it back to rest; run `niri msg action fullscreen-window` and confirm the pill retracts (opacity 0), then toggle fullscreen off again and confirm it returns.

```bash
niri msg action fullscreen-window
sleep 1
niri msg action fullscreen-window
```

- [ ] **Step 4: Stop the test instance**

```bash
pkill -f "qs -c pill"
```

- [ ] **Step 5: Commit**

```bash
yadm add pill/shell.qml
yadm commit -m "Add pill shell.qml: per-monitor windows, mask states, fullscreen retract, IPC"
```

---

### Task 7: Niri keybinds for the pill

**Files:**
- Modify: your niri config (confirm exact path first — typically `~/.config/niri/config.kdl`)

**Interfaces:**
- Consumes: the `IpcHandler { target: "pill" }` handlers from Task 6 (`mixer`, `hide`).

- [ ] **Step 1: Locate the niri config**

```bash
niri msg -j version >/dev/null 2>&1 && ls -la ~/.config/niri/config.kdl
```

- [ ] **Step 2: Add the pill binds**

In the `binds { ... }` block of `~/.config/niri/config.kdl`, add (pick keys that don't already collide — check the file for existing `Mod+M`/`Mod+Escape` binds first):

```kdl
Mod+M { spawn "qs" "-c" "pill" "ipc" "call" "pill" "mixer" ""; }
Mod+Escape { spawn "qs" "-c" "pill" "ipc" "call" "pill" "hide"; }
```

- [ ] **Step 3: Reload niri config**

```bash
niri msg action load-config-file
```

- [ ] **Step 4: Verify the keybind end to end**

With `qs -c pill` running (restart it if it was stopped after Task 6):
```bash
qs -c pill > /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/pill.log 2>&1 &
sleep 2
qs -c pill ipc call pill mixer ""
sleep 1
```
Expected: the mixer surface opens (same visual result as clicking the volume icon). Then:
```bash
qs -c pill ipc call pill hide
pkill -f "qs -c pill"
```

- [ ] **Step 5: Commit**

```bash
yadm add -u ~/.config/niri/config.kdl
yadm commit -m "Add niri keybinds for the pill mixer surface"
```

---

## What this plan does NOT cover (by design — see Global Constraints)

Battery/Wifi/Bluetooth/Brightness/Launcher/Power/Notification/Calendar/Menu surfaces, auto-hide reveal-strip mode, multi-output exclusive-zone tuning beyond the fixed constants used here, and cutting the default `qs` shell over to `pill/`. Each is a follow-up plan once this one is verified working.
