### Task 7: Wire the 4 surfaces into `Pill.qml` and `shell.qml`

**Files:**
- Modify: `pill/Pill.qml`
- Modify: `pill/shell.qml`

**Interfaces:**
- Consumes: `BatteryIndicator`/`BrightnessIndicator`/`WifiIndicator`/`BtIndicator` (Task 1), `BatterySurface`/`BrightnessSurface`/`WifiSurface`/`BtSurface` (Tasks 3-6).
- Produces: `IpcHandler` gains `battery(mon)`, `brightness(mon)`, `wifi(mon)`, `bluetooth(mon)` — consumed by Task 8's niri keybinds.

- [ ] **Step 1: Modify `pill/Pill.qml`**

Read the current file first — you are editing it, not replacing it. Make these specific changes:

1. Add four new `readonly property bool` lines next to the existing `readonly property bool mixerOpen: surface === "mixer"`:

```qml
    readonly property bool batteryOpen: surface === "battery"
    readonly property bool brightnessOpen: surface === "brightness"
    readonly property bool wifiOpen: surface === "wifi"
    readonly property bool bluetoothOpen: surface === "bluetooth"
```

2. Replace the existing `width`/`height` bindings (currently `width: mixerOpen ? mixerWidth : restWidth` and the matching `height:` line) with:

```qml
    readonly property bool anySurfaceOpen: surface.length > 0
    readonly property real openWidth: (wifiOpen || bluetoothOpen) ? (Config.popupWidth * s) : mixerWidth
    readonly property real openContentHeight: {
        if (mixerOpen) return audioSurface.implicitHeight
        if (batteryOpen) return batterySurface.implicitHeight
        if (brightnessOpen) return brightnessSurface.implicitHeight
        if (wifiOpen) return wifiSurface.implicitHeight
        if (bluetoothOpen) return btSurface.implicitHeight
        return 0
    }

    width: anySurfaceOpen ? openWidth : restWidth
    height: anySurfaceOpen ? (openContentHeight + 16) * s : restHeight
```

3. In `restRow`, immediately after the existing volume-icon `Rectangle` (the one containing the `MouseArea` that calls `pill.requestSurface(pill.mixerOpen ? "" : "mixer")`), add four more icons — one per new surface, sized to match the existing icons in the row:

```qml
            BatteryIndicator {
                width: 20 * pill.s
                height: 20 * pill.s
                anchors.verticalCenter: parent.verticalCenter
                horizontal: true
                active: pill.batteryOpen
                onClicked: pill.requestSurface(pill.batteryOpen ? "" : "battery")
            }

            BrightnessIndicator {
                width: 20 * pill.s
                height: 20 * pill.s
                anchors.verticalCenter: parent.verticalCenter
                horizontal: true
                active: pill.brightnessOpen
                onClicked: pill.requestSurface(pill.brightnessOpen ? "" : "brightness")
            }

            WifiIndicator {
                width: 20 * pill.s
                height: 20 * pill.s
                anchors.verticalCenter: parent.verticalCenter
                horizontal: true
                active: pill.wifiOpen
                onClicked: pill.requestSurface(pill.wifiOpen ? "" : "wifi")
            }

            BtIndicator {
                width: 20 * pill.s
                height: 20 * pill.s
                anchors.verticalCenter: parent.verticalCenter
                horizontal: true
                active: pill.bluetoothOpen
                onClicked: pill.requestSurface(pill.bluetoothOpen ? "" : "bluetooth")
            }
```

4. Immediately after the existing `AudioSurface { id: audioSurface ... }` block (inside the same `Rectangle` that hosts it, as a sibling), add the four new surfaces, each following the identical `anchors.fill: parent` / opacity-driven cross-fade pattern already used for `audioSurface`:

```qml
        BatterySurface {
            id: batterySurface
            anchors.fill: parent
            opacity: pill.batteryOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }

        BrightnessSurface {
            id: brightnessSurface
            anchors.fill: parent
            opacity: pill.brightnessOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }

        WifiSurface {
            id: wifiSurface
            anchors.fill: parent
            opacity: pill.wifiOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }

        BtSurface {
            id: btSurface
            anchors.fill: parent
            opacity: pill.bluetoothOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }
```

5. The `restRow`'s `opacity: pill.mixerOpen ? 0 : 1` binding (which hides the rest-state row while the mixer surface is showing) must hide it for every surface, not just the mixer — change it to `opacity: pill.anySurfaceOpen ? 0 : 1`.

- [ ] **Step 2: Modify `pill/shell.qml`**

Read the current file first. In the `IpcHandler { target: "pill" }` block, immediately after the existing `function mixer(mon: string): void { root.toggleSurface(mon, "mixer") }`, add:

```qml
        function battery(mon: string): void { root.toggleSurface(mon, "battery") }
        function brightness(mon: string): void { root.toggleSurface(mon, "brightness") }
        function wifi(mon: string): void { root.toggleSurface(mon, "wifi") }
        function bluetooth(mon: string): void { root.toggleSurface(mon, "bluetooth") }
```

- [ ] **Step 3: Verify**

```bash
qmllint pill/Pill.qml pill/shell.qml 2>&1 | grep -v "is not a type\|Unknown module"
```

Then launch and check the log for errors:

```bash
pkill -f "qs -p .*pill" 2>/dev/null
qs -p ~/.config/quickshell/pill > /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/pill-plan2.log 2>&1 &
sleep 2
grep -iE "error|referenceerror" /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/pill-plan2.log
pgrep -f "qs -p .*pill"
```
Expected: no error/ReferenceError lines, process running.

Exercise each new surface via IPC and screenshot with `grim` (same method as Plan 1's Task 6):
```bash
qs -p ~/.config/quickshell/pill ipc call pill battery ""
grim -o "$(niri msg -j outputs | python3 -c 'import json,sys; print(list(json.load(sys.stdin).keys())[0])')" /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/battery-surface.png
qs -p ~/.config/quickshell/pill ipc call pill hide
# repeat for brightness, wifi, bluetooth
```

Then:
```bash
pkill -f "qs -p .*pill"
```

- [ ] **Step 4: Commit**

```bash
yadm add pill/Pill.qml pill/shell.qml
yadm commit -m "Wire battery, brightness, wifi, bluetooth surfaces into Pill.qml and shell.qml"
```

---

