## Commits
2b41cfc8 Add niri keybinds for battery, brightness, wifi, bluetooth pill surfaces
c366ea53 Wire battery, brightness, wifi, bluetooth surfaces into Pill.qml and shell.qml
505db84f Port the bluetooth popup content into a pill-hosted BtSurface
99c261a7 Port the wifi popup content into a pill-hosted WifiSurface
e1ec2958 Port the brightness popup content into a pill-hosted BrightnessSurface
3f086dc9 Port the battery popup content into a pill-hosted BatterySurface
c3cc6b4e Fork IconButton, ListItem, TextFieldControl, ActionButton into pill/components/
c539ca69 Fork StatusIndicator and the 4 rest-row Indicators into pill/components/

## Diffstat
 .config/niri/keybinds.kdl                          |   7 +
 .config/quickshell/pill/Pill.qml                   |  89 ++++-
 .../quickshell/pill/components/ActionButton.qml    | 101 +++++
 .../pill/components/BatteryIndicator.qml           |  46 +++
 .../pill/components/BrightnessIndicator.qml        |  84 ++++
 .config/quickshell/pill/components/BtIndicator.qml |  65 +++
 .config/quickshell/pill/components/IconButton.qml  |  90 +++++
 .config/quickshell/pill/components/ListItem.qml    | 146 +++++++
 .../quickshell/pill/components/StatusIndicator.qml | 161 ++++++++
 .../pill/components/TextFieldControl.qml           | 106 +++++
 .../quickshell/pill/components/WifiIndicator.qml   |  66 ++++
 .config/quickshell/pill/shell.qml                  |   4 +
 .../quickshell/pill/surfaces/BatterySurface.qml    | 202 ++++++++++
 .../quickshell/pill/surfaces/BrightnessSurface.qml |  94 +++++
 .config/quickshell/pill/surfaces/BtSurface.qml     | 247 ++++++++++++
 .config/quickshell/pill/surfaces/WifiSurface.qml   | 434 +++++++++++++++++++++
 16 files changed, 1939 insertions(+), 3 deletions(-)

## Full diff
diff --git a/.config/niri/keybinds.kdl b/.config/niri/keybinds.kdl
index dacca73b..c558ec84 100644
--- a/.config/niri/keybinds.kdl
+++ b/.config/niri/keybinds.kdl
@@ -9,20 +9,27 @@ binds {
   Mod+B hotkey-overlay-title="Open Web Browser: Brave Browser" { spawn "brave-origin"; }
   Mod+T hotkey-overlay-title="Open File Manager: Nautilus" { spawn "nautilus"; }
   Mod+Escape repeat=false hotkey-overlay-title="Open Quick Settings" { spawn "~/.config/quickshell/scripts/quickmenu"; }
   Mod+A hotkey-overlay-title="Open OpenCode" { spawn "kitty" "-e" "opencode"; }
 
   // Pill shell (Quickshell -p pill): mixer surface toggle/hide.
   // Mod+Escape is already bound above (Open Quick Settings), so hide uses Mod+Shift+Escape.
   Mod+M hotkey-overlay-title="Open Pill Mixer" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "mixer" ""; }
   Mod+Shift+Escape repeat=false hotkey-overlay-title="Hide Pill Mixer" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "hide"; }
 
+  // Pill shell (Quickshell -p pill): battery/brightness/wifi/bluetooth surfaces.
+  // Mod+Shift+U collides with move-workspace-down (below), so bluetooth uses Mod+Shift+T instead.
+  Mod+Shift+B hotkey-overlay-title="Open Pill Battery" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "battery" ""; }
+  Mod+Shift+N hotkey-overlay-title="Open Pill Brightness" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "brightness" ""; }
+  Mod+Shift+W hotkey-overlay-title="Open Pill Wifi" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "wifi" ""; }
+  Mod+Shift+T hotkey-overlay-title="Open Pill Bluetooth" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "bluetooth" ""; }
+
   // Use spawn-sh to run a shell command. Do this if you need pipes, multiple commands, etc.
   // Note: the entire command goes as a single argument. It's passed verbatim to `sh -c`.
   // For example, this is a standard bind to toggle the screen reader (orca).
   Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; }
 
   // Example volume keys mappings for PipeWire & WirePlumber.
   // The allow-when-locked=true property makes them work even when the session is locked.
   // Using spawn-sh allows to pass multiple arguments together with the command.
   // "-l 1.0" limits the volume to 100%.
   XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0 && touch /tmp/qsosd-vol"; }
diff --git a/.config/quickshell/pill/Pill.qml b/.config/quickshell/pill/Pill.qml
index 9aa94b2b..d0993790 100644
--- a/.config/quickshell/pill/Pill.qml
+++ b/.config/quickshell/pill/Pill.qml
@@ -8,30 +8,45 @@ Item {
     id: pill
 
     property real s: 1
     property string surface: ""
     property bool hovered: false
     property bool pinned: false
 
     readonly property bool held: pinned
     readonly property bool expanded: hovered || held || surface.length > 0
     readonly property bool mixerOpen: surface === "mixer"
+    readonly property bool batteryOpen: surface === "battery"
+    readonly property bool brightnessOpen: surface === "brightness"
+    readonly property bool wifiOpen: surface === "wifi"
+    readonly property bool bluetoothOpen: surface === "bluetooth"
 
     readonly property real restWidth: (restRow.implicitWidth + 28) * s
     readonly property real restHeight: 38 * s
     readonly property real mixerWidth: 280 * s
 
     signal requestSurface(string name)
     signal requestClose()
 
-    width: mixerOpen ? mixerWidth : restWidth
-    height: mixerOpen ? (audioSurface.implicitHeight + 16) * s : restHeight
+    readonly property bool anySurfaceOpen: surface.length > 0
+    readonly property real openWidth: (wifiOpen || bluetoothOpen) ? (Config.popupWidth * s) : mixerWidth
+    readonly property real openContentHeight: {
+        if (mixerOpen) return audioSurface.implicitHeight
+        if (batteryOpen) return batterySurface.implicitHeight
+        if (brightnessOpen) return brightnessSurface.implicitHeight
+        if (wifiOpen) return wifiSurface.implicitHeight
+        if (bluetoothOpen) return btSurface.implicitHeight
+        return 0
+    }
+
+    width: anySurfaceOpen ? openWidth : restWidth
+    height: anySurfaceOpen ? (openContentHeight + 16) * s : restHeight
 
     Behavior on width {
         NumberAnimation {
             duration: Motion.morph
             easing.type: Motion.easeMorph
             easing.bezierCurve: Motion.morphCurve
         }
     }
     Behavior on height {
         NumberAnimation {
@@ -55,21 +70,21 @@ Item {
         clip: true
 
         Behavior on radius {
             NumberAnimation { duration: Motion.morph; easing.type: Easing.OutCubic }
         }
 
         Row {
             id: restRow
             anchors.centerIn: parent
             spacing: 10 * pill.s
-            opacity: pill.mixerOpen ? 0 : 1
+            opacity: pill.anySurfaceOpen ? 0 : 1
             visible: opacity > 0
             Behavior on opacity { NumberAnimation { duration: Motion.fast } }
 
             WorkspaceDots {
                 anchors.verticalCenter: parent.verticalCenter
             }
 
             Rectangle {
                 width: 20 * pill.s
                 height: 20 * pill.s
@@ -84,24 +99,92 @@ Item {
                     font.pixelSize: Config.iconSize
                     color: Colors.fgSurface
                 }
 
                 MouseArea {
                     anchors.fill: parent
                     cursorShape: Qt.PointingHandCursor
                     onClicked: pill.requestSurface(pill.mixerOpen ? "" : "mixer")
                 }
             }
+
+            BatteryIndicator {
+                width: 20 * pill.s
+                height: 20 * pill.s
+                anchors.verticalCenter: parent.verticalCenter
+                horizontal: true
+                active: pill.batteryOpen
+                onClicked: pill.requestSurface(pill.batteryOpen ? "" : "battery")
+            }
+
+            BrightnessIndicator {
+                width: 20 * pill.s
+                height: 20 * pill.s
+                anchors.verticalCenter: parent.verticalCenter
+                horizontal: true
+                active: pill.brightnessOpen
+                onClicked: pill.requestSurface(pill.brightnessOpen ? "" : "brightness")
+            }
+
+            WifiIndicator {
+                width: 20 * pill.s
+                height: 20 * pill.s
+                anchors.verticalCenter: parent.verticalCenter
+                horizontal: true
+                active: pill.wifiOpen
+                onClicked: pill.requestSurface(pill.wifiOpen ? "" : "wifi")
+            }
+
+            BtIndicator {
+                width: 20 * pill.s
+                height: 20 * pill.s
+                anchors.verticalCenter: parent.verticalCenter
+                horizontal: true
+                active: pill.bluetoothOpen
+                onClicked: pill.requestSurface(pill.bluetoothOpen ? "" : "bluetooth")
+            }
         }
 
         AudioSurface {
             id: audioSurface
             anchors.fill: parent
             anchors.margins: 0
             opacity: pill.mixerOpen ? 1 : 0
             visible: opacity > 0
             Behavior on opacity { NumberAnimation { duration: Motion.fast } }
         }
+
+        BatterySurface {
+            id: batterySurface
+            anchors.fill: parent
+            opacity: pill.batteryOpen ? 1 : 0
+            visible: opacity > 0
+            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
+        }
+
+        BrightnessSurface {
+            id: brightnessSurface
+            anchors.fill: parent
+            opacity: pill.brightnessOpen ? 1 : 0
+            visible: opacity > 0
+            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
+        }
+
+        WifiSurface {
+            id: wifiSurface
+            anchors.fill: parent
+            opacity: pill.wifiOpen ? 1 : 0
+            visible: opacity > 0
+            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
+        }
+
+        BtSurface {
+            id: btSurface
+            anchors.fill: parent
+            opacity: pill.bluetoothOpen ? 1 : 0
+            visible: opacity > 0
+            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
+        }
     }
 
     Keys.onEscapePressed: pill.requestClose()
 }
diff --git a/.config/quickshell/pill/components/ActionButton.qml b/.config/quickshell/pill/components/ActionButton.qml
new file mode 100644
index 00000000..43940091
--- /dev/null
+++ b/.config/quickshell/pill/components/ActionButton.qml
@@ -0,0 +1,101 @@
+// Forked from bar/primitives/ActionButton.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Controls
+import "../config"
+
+Rectangle {
+  id: root
+
+  property string iconLabel: ""
+  property bool selected: false
+  property string labelText: ""
+  property string variant: "tonal"
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property string tooltipText: ""
+  readonly property bool filled: root.selected || root.variant === "filled"
+  property real iconSize: Config.iconSize + 4
+  property color iconColor: root.filled ? Colors.fgPrimary : Colors.fgSurfaceVariant
+
+  signal activated()
+
+  radius: 20
+  activeFocusOnTab: true
+  opacity: root.enabled ? 1.0 : 0.38
+
+  readonly property bool hovered: mouseArea.containsMouse
+  readonly property bool pressed: mouseArea.pressed
+
+  Accessible.role: Accessible.Button
+  Accessible.name: root.accessibleName !== ""
+    ? root.accessibleName
+    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel))
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.selected ? "Selected" : "")
+
+  color: {
+    var overlay = mouseArea.pressed ? Colors.pressOverlay
+      : (mouseArea.containsMouse ? Colors.hoverOverlay
+        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
+    var base = root.filled
+      ? Colors.primary
+      : (root.variant === "quiet" ? "transparent" : Colors.surfaceContainer)
+    return Qt.tint(base, overlay)
+  }
+  border.color: root.filled || root.variant === "quiet"
+    ? "transparent"
+    : (root.variant === "outlined"
+      ? Colors.outline
+      : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15))
+  border.width: 1
+
+  Behavior on color {
+    ColorAnimation { duration: Config.animationDuration }
+  }
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.activated()
+      event.accepted = true
+    }
+  }
+
+  Column {
+    anchors.centerIn: parent
+    spacing: root.labelText !== "" ? 2 : 0
+
+    Text {
+      anchors.horizontalCenter: parent.horizontalCenter
+      text: root.iconLabel
+      color: root.iconColor
+      font.family: Config.iconFont
+      font.pixelSize: root.iconSize
+    }
+
+    Text {
+      visible: root.labelText !== ""
+      anchors.horizontalCenter: parent.horizontalCenter
+      text: root.labelText
+      color: root.iconColor
+      font.family: Config.fontFamily
+      font.pixelSize: Config.fontPixelSize
+      font.weight: Font.Medium
+    }
+  }
+
+  MouseArea {
+    id: mouseArea
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: {
+      root.forceActiveFocus()
+      root.activated()
+    }
+  }
+}
diff --git a/.config/quickshell/pill/components/BatteryIndicator.qml b/.config/quickshell/pill/components/BatteryIndicator.qml
new file mode 100644
index 00000000..2b154332
--- /dev/null
+++ b/.config/quickshell/pill/components/BatteryIndicator.qml
@@ -0,0 +1,46 @@
+// Forked from bar/BatteryIndicator.qml (identical apart from import paths,
+// with the "primitives" import dropped since StatusIndicator is now a
+// same-directory sibling). Cross-root import is impossible under 'qs -p';
+// see docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in
+// sync until bar/ is retired.
+import QtQuick
+import QtQuick.Layouts
+import Quickshell
+import Quickshell.Services.UPower
+import "../config"
+
+StatusIndicator {
+  id: root
+
+  accentColor: Colors.primary
+  accessibleName: "Battery"
+
+  readonly property var batteryDevice: {
+    for (var i = 0; i < UPower.devices.count; i++) {
+      var d = UPower.devices.get(i)
+      if (d.ready && d.isLaptopBattery) return d
+    }
+    if (UPower.displayDevice && UPower.displayDevice.ready)
+      return UPower.displayDevice
+    return null
+  }
+
+  readonly property real pct: batteryDevice ? batteryDevice.percentage * 100 : -1
+
+  iconLabel: {
+    if (!batteryDevice) return "battery_unknown"
+    var ch = batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge
+    var plugged = ch || batteryDevice.state === UPowerDeviceState.FullyCharged
+    if (ch) return "battery_charging_full"
+    if (plugged && pct >= 99) return "battery_full"
+    if (pct <= 10) return "battery_alert"
+    if (pct <= 20) return "battery_1_bar"
+    if (pct <= 40) return "battery_2_bar"
+    if (pct <= 60) return "battery_3_bar"
+    if (pct <= 80) return "battery_4_bar"
+    if (pct <= 95) return "battery_5_bar"
+    return "battery_full"
+  }
+
+  labelText: root.pct >= 0 ? Math.round(root.pct) + "%" : ""
+}
diff --git a/.config/quickshell/pill/components/BrightnessIndicator.qml b/.config/quickshell/pill/components/BrightnessIndicator.qml
new file mode 100644
index 00000000..fdc9169c
--- /dev/null
+++ b/.config/quickshell/pill/components/BrightnessIndicator.qml
@@ -0,0 +1,84 @@
+// Forked from bar/BrightnessIndicator.qml (identical apart from import
+// paths, with the "primitives" import dropped since StatusIndicator is now
+// a same-directory sibling). Cross-root import is impossible under
+// 'qs -p'; see docs/superpowers/plans/2026-08-09-pill-shell-foundation.md.
+// Keep in sync until bar/ is retired.
+import QtQuick
+import Quickshell
+import Quickshell.Io
+import "../config"
+
+StatusIndicator {
+  id: root
+
+  accentColor: Colors.brightness
+  accessibleName: "Brightness"
+  tooltipText: "Brightness"
+
+  property real pct: 0
+  property bool initialized: false
+
+  Process {
+    id: getProc
+    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var val = parseFloat(text.trim())
+        if (!isNaN(val)) {
+          root.pct = val
+          root.initialized = true
+        }
+      }
+    }
+  }
+
+  function fetchBrightness() { getProc.running = true }
+
+  function setBrightness(val) {
+    root.pct = Math.max(0, Math.min(100, val))
+    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pct) + "%"])
+  }
+
+  Process {
+    id: brightnessWatcher
+    command: ["sh", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness"]
+    running: root.visible
+    stdout: SplitParser {
+      onRead: function(data) { root.fetchBrightness() }
+    }
+    onRunningChanged: {
+      if (!running && root.visible) brightnessWatcherRetry.start()
+    }
+  }
+
+  Timer {
+    id: brightnessWatcherRetry
+    interval: 1000
+    onTriggered: {
+      if (root.visible) brightnessWatcher.running = true
+    }
+  }
+
+  onVisibleChanged: {
+    if (visible) root.fetchBrightness()
+  }
+
+  Component.onCompleted: {
+    if (root.visible) root.fetchBrightness()
+  }
+
+  iconLabel: {
+    if (!root.initialized) return "brightness_medium"
+    if (root.pct <= 10) return "brightness_empty"
+    if (root.pct <= 40) return "brightness_low"
+    if (root.pct <= 70) return "brightness_medium"
+    return "brightness_high"
+  }
+  labelText: root.initialized ? Math.round(root.pct) + "%" : ""
+
+  onWheel: function(wheel) {
+    var delta = wheel.angleDelta.y > 0 ? Config.brightnessStep : -Config.brightnessStep
+    root.setBrightness(root.pct + delta)
+  }
+}
diff --git a/.config/quickshell/pill/components/BtIndicator.qml b/.config/quickshell/pill/components/BtIndicator.qml
new file mode 100644
index 00000000..344a38f3
--- /dev/null
+++ b/.config/quickshell/pill/components/BtIndicator.qml
@@ -0,0 +1,65 @@
+// Forked from bar/BtIndicator.qml (identical apart from import paths, with
+// the "primitives" import dropped since StatusIndicator is now a
+// same-directory sibling). Cross-root import is impossible under 'qs -p';
+// see docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in
+// sync until bar/ is retired.
+import QtQuick
+import Quickshell
+import Quickshell.Io
+import "../config"
+
+StatusIndicator {
+  id: root
+
+  accentColor: Colors.primary
+  accessibleName: "Bluetooth"
+  tooltipText: "Bluetooth"
+
+  property bool btOn: false
+  property string btDeviceMac: ""
+  property string btDeviceBattery: ""
+
+  Process {
+    id: btQuery
+    command: ["sh", "-c", "echo $(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')___$(MAC=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2) && [ -n \"$MAC\" ] && echo \"$MAC\" || echo \"\")___$(MAC=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2) && [ -n \"$MAC\" ] && bluetoothctl info \"$MAC\" 2>/dev/null | grep \"Battery Percentage:\" | awk -F '[()]' '{print $2}' || echo \"\")"]
+    running: false
+
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var clean = text.trim()
+        var parts = clean.split("___")
+        root.btOn = parts[0] === "yes"
+        root.btDeviceMac = parts.length > 1 ? parts[1] : ""
+        root.btDeviceBattery = parts.length > 2 ? parts[2].trim() : ""
+      }
+    }
+  }
+
+  Timer {
+    id: pollTimer
+    interval: 5000
+    running: root.visible
+    repeat: true
+    triggeredOnStart: true
+    onTriggered: btQuery.running = true
+  }
+
+  onVisibleChanged: {
+    if (visible) btQuery.running = true
+  }
+
+  Component.onCompleted: {
+    if (root.visible) btQuery.running = true
+  }
+
+  iconLabel: {
+    if (!root.btOn) return "bluetooth_disabled"
+    if (root.btDeviceMac !== "") return "bluetooth_connected"
+    return "bluetooth"
+  }
+  labelText: {
+    if (!root.btOn) return "Off"
+    if (root.btDeviceMac !== "" && root.btDeviceBattery !== "") return root.btDeviceBattery + "%"
+    return "On"
+  }
+}
diff --git a/.config/quickshell/pill/components/IconButton.qml b/.config/quickshell/pill/components/IconButton.qml
new file mode 100644
index 00000000..eef37c3b
--- /dev/null
+++ b/.config/quickshell/pill/components/IconButton.qml
@@ -0,0 +1,90 @@
+// Forked from bar/primitives/IconButton.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Controls
+import "../config"
+
+Item {
+  id: root
+
+  property string iconLabel: ""
+  property int size: 32
+  property int iconSize: 18
+  property color iconColor: Colors.fgSurface
+  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
+  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
+  property color backgroundColor: "transparent"
+  property color borderColor: Colors.outlineVariant
+  property bool outlined: false
+  property bool enabled: true
+  property bool selected: false
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property string tooltipText: ""
+
+  signal clicked(var mouse)
+  signal wheel(var wheel)
+
+  implicitWidth: size
+  implicitHeight: size
+  activeFocusOnTab: root.enabled
+  opacity: root.enabled ? 1.0 : 0.38
+
+  readonly property bool hovered: mouseArea.containsMouse
+  readonly property bool pressed: mouseArea.pressed
+
+  Accessible.role: Accessible.Button
+  Accessible.name: root.accessibleName !== ""
+    ? root.accessibleName
+    : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel)
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.selected ? "Selected" : "")
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.clicked(null)
+      event.accepted = true
+    }
+  }
+
+  Rectangle {
+    anchors.fill: parent
+    radius: root.size / 2
+    color: !root.enabled ? "transparent"
+      : root.selected ? Qt.tint(Colors.primaryContainer, root.pressColor)
+      : (mouseArea.pressed ? root.pressColor
+        : (mouseArea.containsMouse ? root.hoverColor
+          : (root.activeFocus ? Colors.focusOverlay : root.backgroundColor)))
+    border.width: root.outlined ? 1 : 0
+    border.color: root.borderColor
+
+    Behavior on color {
+      ColorAnimation { duration: Config.animationDuration }
+    }
+  }
+
+  Text {
+    anchors.centerIn: parent
+    text: root.iconLabel
+    color: root.iconColor
+    opacity: root.enabled ? 1.0 : 0.38
+    font.family: Config.iconFont
+    font.pixelSize: root.iconSize
+  }
+
+  MouseArea {
+    id: mouseArea
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: function(mouse) {
+      root.forceActiveFocus()
+      root.clicked(mouse)
+    }
+    onWheel: function(wheelEvent) { root.wheel(wheelEvent) }
+  }
+}
diff --git a/.config/quickshell/pill/components/ListItem.qml b/.config/quickshell/pill/components/ListItem.qml
new file mode 100644
index 00000000..3ac45015
--- /dev/null
+++ b/.config/quickshell/pill/components/ListItem.qml
@@ -0,0 +1,146 @@
+// Forked from bar/primitives/ListItem.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Layouts
+import "../config"
+
+Rectangle {
+  id: root
+
+  default property alias trailingContent: trailingRow.data
+
+  property string leadingIcon: ""
+  property real leadingIconOpacity: 1.0
+  property string leadingImageSource: ""
+  property string leadingFallbackText: ""
+  property string title: ""
+  property string subtitle: ""
+  property bool selected: false
+  property color leadingIconColor: root.selected ? Colors.primary : Colors.fgSurface
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  readonly property bool hovered: itemMouse.containsMouse
+  readonly property bool pressed: itemMouse.pressed
+
+  signal clicked(var mouse)
+
+  height: 44
+  radius: Config.shapeMedium
+  activeFocusOnTab: root.enabled
+  opacity: root.enabled ? 1.0 : 0.38
+
+  Accessible.role: Accessible.ListItem
+  Accessible.name: root.accessibleName !== "" ? root.accessibleName : root.title
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.selected ? root.subtitle + " Selected" : root.subtitle)
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.clicked(null)
+      event.accepted = true
+    }
+  }
+  color: {
+    if (root.selected) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
+    if (itemMouse.containsMouse) return Qt.tint("transparent", Colors.hoverOverlay)
+    return root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
+  }
+  border.color: root.selected ? Colors.primary : "transparent"
+  border.width: 1
+
+  Behavior on color {
+    ColorAnimation { duration: Config.animationDuration }
+  }
+
+  MouseArea {
+    id: itemMouse
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: function(mouse) {
+      root.forceActiveFocus()
+      root.clicked(mouse)
+    }
+  }
+
+  RowLayout {
+    anchors.fill: parent
+    anchors.leftMargin: 8
+    anchors.rightMargin: 8
+    spacing: 10
+
+    Text {
+      visible: root.leadingIcon !== "" && root.leadingImageSource === ""
+      text: root.leadingIcon
+      color: root.leadingIconColor
+      opacity: root.leadingIconOpacity
+      font.family: Config.iconFont
+      font.pixelSize: 22
+    }
+
+    Rectangle {
+      visible: root.leadingImageSource !== "" || root.leadingFallbackText !== ""
+      width: 30
+      height: 30
+      radius: 15
+      color: Colors.surfaceContainerHigh
+
+      Image {
+        anchors.centerIn: parent
+        width: 20
+        height: 20
+        source: root.leadingImageSource
+        sourceSize.width: 20
+        sourceSize.height: 20
+        smooth: true
+        fillMode: Image.PreserveAspectFit
+        visible: root.leadingImageSource !== ""
+      }
+
+      Text {
+        anchors.centerIn: parent
+        text: root.leadingFallbackText
+        color: Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: 14
+        font.weight: Font.Medium
+        visible: root.leadingImageSource === "" && root.leadingFallbackText !== ""
+      }
+    }
+
+    ColumnLayout {
+      Layout.fillWidth: true
+      spacing: 0
+
+      Text {
+        Layout.fillWidth: true
+        text: root.title
+        color: root.selected ? Colors.primary : Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 3)
+        font.weight: Font.Medium
+        elide: Text.ElideRight
+      }
+
+      Text {
+        Layout.fillWidth: true
+        visible: root.subtitle !== ""
+        text: root.subtitle
+        color: Colors.fgSurfaceVariant
+        font.family: Config.fontFamily
+        font.pixelSize: Config.fontPixelSize
+        elide: Text.ElideRight
+      }
+    }
+
+    Row {
+      id: trailingRow
+      spacing: 4
+      Layout.alignment: Qt.AlignVCenter
+    }
+  }
+}
diff --git a/.config/quickshell/pill/components/StatusIndicator.qml b/.config/quickshell/pill/components/StatusIndicator.qml
new file mode 100644
index 00000000..b4b72b67
--- /dev/null
+++ b/.config/quickshell/pill/components/StatusIndicator.qml
@@ -0,0 +1,161 @@
+// Forked from bar/primitives/StatusIndicator.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Controls
+import QtQuick.Layouts
+import "../config"
+
+Item {
+  id: root
+
+  property bool horizontal: false
+  property bool active: false
+  property string iconLabel: ""
+  property real iconOpacity: 1.0
+  property string labelText: ""
+  property real labelOpacity: 1.0
+  property color accentColor: Colors.primary
+  property color iconColor: root.accentColor
+  property color labelColor: root.accentColor
+  property color inactiveBg: Colors.surfaceContainerHigh
+  property bool borderOnHoverOnly: true
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property string tooltipText: ""
+  property string badgeText: ""
+  property color badgeColor: Colors.error
+  property color badgeTextColor: Colors.fgError
+
+  signal clicked(var mouse)
+  signal wheel(var wheel)
+
+  Layout.preferredWidth: Config.widgetSize
+  Layout.preferredHeight: Config.widgetSize
+  activeFocusOnTab: root.enabled
+  opacity: root.enabled ? 1.0 : 0.38
+
+  readonly property bool hovered: mouseArea.containsMouse
+  readonly property bool pressed: mouseArea.pressed
+
+  Accessible.role: Accessible.Button
+  Accessible.name: root.accessibleName !== ""
+    ? root.accessibleName
+    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : "Status indicator"))
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.active ? "Active" : "")
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.clicked(null)
+      event.accepted = true
+    }
+  }
+
+  Rectangle {
+    id: bgOverlay
+    anchors {
+      fill: parent
+      leftMargin: root.horizontal ? 0 : 6
+      rightMargin: root.horizontal ? 0 : 6
+      topMargin: root.horizontal ? 6 : 0
+      bottomMargin: root.horizontal ? 6 : 0
+    }
+    radius: root.horizontal ? height / 2 : width / 2
+    clip: true
+    color: {
+      var overlay = mouseArea.pressed ? Colors.pressOverlay
+        : (mouseArea.containsMouse ? Colors.hoverOverlay
+          : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
+      var base = root.borderOnHoverOnly ? "transparent" : root.inactiveBg
+      return Qt.tint(base, overlay)
+    }
+    border.color: {
+      if (root.active) return root.activeFocus ? Colors.focusOverlay : "transparent"
+      if (root.borderOnHoverOnly && !mouseArea.containsMouse && !root.activeFocus) return "transparent"
+      return Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
+    }
+    border.width: 1
+
+    Behavior on color {
+      ColorAnimation { duration: Config.animationDuration }
+    }
+  }
+
+  Column {
+    id: contentColumn
+    anchors.centerIn: parent
+    width: parent.width
+    spacing: root.labelText !== "" ? Config.spacingCompact : 0
+
+    Text {
+      id: iconText
+      width: parent.width
+      height: Config.iconSize
+      text: root.iconLabel
+      opacity: root.iconOpacity
+      color: root.iconColor
+      font.family: Config.iconFont
+      font.pixelSize: Config.iconSize
+      horizontalAlignment: Text.AlignHCenter
+      verticalAlignment: Text.AlignVCenter
+    }
+
+    Text {
+      id: labelTextItem
+      visible: root.labelText !== ""
+      width: parent.width
+      text: root.labelText
+      opacity: root.labelOpacity
+      color: root.labelColor
+      font.family: Config.fontFamily
+      font.pixelSize: Config.labelSmallSize
+      font.weight: Font.Medium
+      horizontalAlignment: Text.AlignHCenter
+      elide: Text.ElideRight
+    }
+  }
+
+  Item {
+    anchors.fill: parent
+    visible: root.badgeText !== ""
+
+    Rectangle {
+      anchors.right: parent.right
+      anchors.top: parent.top
+      anchors.rightMargin: 4
+      anchors.topMargin: 4
+      width: badgeLabel.implicitWidth + 6
+      height: 14
+      radius: 7
+      color: root.badgeColor
+
+      Text {
+        id: badgeLabel
+        anchors.centerIn: parent
+        text: root.badgeText
+        color: root.badgeTextColor
+        font.family: Config.fontFamily
+        font.pixelSize: Config.fontPixelSize - 3
+        font.weight: Font.Bold
+        horizontalAlignment: Text.AlignHCenter
+        verticalAlignment: Text.AlignVCenter
+      }
+    }
+  }
+
+  MouseArea {
+    id: mouseArea
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: function(mouse) {
+      root.forceActiveFocus()
+      root.clicked(mouse)
+    }
+    onWheel: function(wheelEvent) { root.wheel(wheelEvent) }
+  }
+}
diff --git a/.config/quickshell/pill/components/TextFieldControl.qml b/.config/quickshell/pill/components/TextFieldControl.qml
new file mode 100644
index 00000000..cfacee39
--- /dev/null
+++ b/.config/quickshell/pill/components/TextFieldControl.qml
@@ -0,0 +1,106 @@
+// Forked from bar/primitives/TextFieldControl.qml (identical apart from
+// import paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Layouts
+import "../config"
+
+Rectangle {
+  id: root
+
+  property alias text: input.text
+  property string placeholder: ""
+  property int echoMode: TextInput.Normal
+  property alias input: input
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property bool showPlaceholderOnFocus: false
+  property bool captureHorizontalArrows: false
+  property string leadingIcon: ""
+  property color leadingIconColor: Colors.fgSurfaceVariant
+  property real leadingIconSize: 22
+
+  default property alias trailingContent: trailingRow.data
+
+  signal accepted()
+  signal escapePressed()
+  signal upPressed()
+  signal downPressed()
+  signal leftPressed()
+  signal rightPressed()
+
+  height: 36
+  radius: 8
+  color: Colors.surface
+  border.color: input.activeFocus ? Colors.primary : Colors.outline
+  border.width: input.activeFocus ? 2 : 1
+
+  RowLayout {
+    anchors {
+      fill: parent
+      leftMargin: 10
+      rightMargin: 10
+    }
+    spacing: 8
+
+    Text {
+      visible: root.leadingIcon !== ""
+      text: root.leadingIcon
+      color: root.leadingIconColor
+      font.family: Config.iconFont
+      font.pixelSize: root.leadingIconSize
+      Layout.alignment: Qt.AlignVCenter
+    }
+
+    TextInput {
+      id: input
+      Layout.fillWidth: true
+      Layout.fillHeight: true
+      verticalAlignment: TextInput.AlignVCenter
+      color: Colors.fgSurface
+      font.family: Config.fontFamily
+      font.pixelSize: Config.fontPixelSize + 2
+      echoMode: root.echoMode
+      activeFocusOnTab: true
+      Accessible.role: Accessible.EditableText
+      Accessible.name: root.accessibleName !== ""
+        ? root.accessibleName
+        : (root.placeholder !== "" ? root.placeholder : "Text field")
+      Accessible.description: root.accessibleDescription
+      Keys.onPressed: function(event) {
+        if (event.key === Qt.Key_Escape) {
+          root.escapePressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Up) {
+          root.upPressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Down) {
+          root.downPressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Left && root.captureHorizontalArrows) {
+          root.leftPressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Right && root.captureHorizontalArrows) {
+          root.rightPressed()
+          event.accepted = true
+        }
+      }
+      onAccepted: root.accepted()
+
+      Text {
+        text: root.placeholder
+        color: Colors.fgSurfaceVariant
+        visible: !parent.text && (!parent.activeFocus || root.showPlaceholderOnFocus)
+        font: parent.font
+        anchors.verticalCenter: parent.verticalCenter
+      }
+    }
+
+    Row {
+      id: trailingRow
+      spacing: 4
+      Layout.alignment: Qt.AlignVCenter
+    }
+  }
+}
diff --git a/.config/quickshell/pill/components/WifiIndicator.qml b/.config/quickshell/pill/components/WifiIndicator.qml
new file mode 100644
index 00000000..0d627201
--- /dev/null
+++ b/.config/quickshell/pill/components/WifiIndicator.qml
@@ -0,0 +1,66 @@
+// Forked from bar/WifiIndicator.qml (identical apart from import paths,
+// with the "primitives" import dropped since StatusIndicator is now a
+// same-directory sibling). Cross-root import is impossible under 'qs -p';
+// see docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in
+// sync until bar/ is retired.
+import QtQuick
+import Quickshell
+import Quickshell.Io
+import "../config"
+
+StatusIndicator {
+  id: root
+
+  accentColor: Colors.primary
+  accessibleName: "Wi-Fi"
+  tooltipText: "Wi-Fi"
+
+  property bool wifiOn: false
+  property int wifiSignal: -1
+
+  iconLabel: "wifi"
+
+  Process {
+    id: wifiQuery
+    command: ["sh", "-c", "echo $(nmcli radio wifi)___$(nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)"]
+    running: false
+
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var clean = text.trim()
+        var parts = clean.split("___")
+        root.wifiOn = parts[0] === "enabled"
+        if (parts.length > 1 && parts[1]) {
+          var sig = parseInt(parts[1])
+          root.wifiSignal = isNaN(sig) ? -1 : sig
+        } else {
+          root.wifiSignal = -1
+        }
+      }
+    }
+  }
+
+  Timer {
+    id: pollTimer
+    interval: 10000
+    running: root.visible
+    repeat: true
+    triggeredOnStart: true
+    onTriggered: wifiQuery.running = true
+  }
+
+  iconOpacity: {
+    if (!root.wifiOn) return 0.25
+    if (root.wifiSignal < 0) return 0.4
+    if (root.wifiSignal <= 25) return 0.55
+    if (root.wifiSignal <= 50) return 0.7
+    if (root.wifiSignal <= 75) return 0.85
+    return 1.0
+  }
+  labelText: root.wifiOn && root.wifiSignal >= 0 ? root.wifiSignal + "%" : "--%"
+  labelOpacity: {
+    if (!root.wifiOn) return 0.35
+    if (root.wifiSignal < 0) return 0.5
+    return 1.0
+  }
+}
diff --git a/.config/quickshell/pill/shell.qml b/.config/quickshell/pill/shell.qml
index 2588617b..1d4d18c0 100644
--- a/.config/quickshell/pill/shell.qml
+++ b/.config/quickshell/pill/shell.qml
@@ -22,20 +22,24 @@ ShellRoot {
     }
 
     function close() {
         root.openMon = ""
         root.openSurface = ""
     }
 
     IpcHandler {
         target: "pill"
         function mixer(mon: string): void { root.toggleSurface(mon, "mixer") }
+        function battery(mon: string): void { root.toggleSurface(mon, "battery") }
+        function brightness(mon: string): void { root.toggleSurface(mon, "brightness") }
+        function wifi(mon: string): void { root.toggleSurface(mon, "wifi") }
+        function bluetooth(mon: string): void { root.toggleSurface(mon, "bluetooth") }
         function hide(): void { root.close() }
     }
 
     Variants {
         model: Quickshell.screens
 
         PanelWindow {
             id: reserve
             required property var modelData
             readonly property real topGap: 8
diff --git a/.config/quickshell/pill/surfaces/BatterySurface.qml b/.config/quickshell/pill/surfaces/BatterySurface.qml
new file mode 100644
index 00000000..d30c466c
--- /dev/null
+++ b/.config/quickshell/pill/surfaces/BatterySurface.qml
@@ -0,0 +1,202 @@
+import QtQuick
+import QtQuick.Layouts
+import Quickshell
+import Quickshell.Services.UPower
+import Quickshell.Io
+import "../components"
+import "../config"
+
+Item {
+  id: root
+
+  implicitHeight: contentColumn.implicitHeight + 24
+
+  property var batteryDevice: null
+  property real pct: -1
+  property var state: null
+  property bool charging: false
+  property string stateLabel: "No battery"
+  property string timeLabel: ""
+  property string cycles: "--"
+
+  function formatTime(seconds) {
+    if (!seconds || seconds <= 0) return ""
+    var h = Math.floor(seconds / 3600)
+    var m = Math.floor((seconds % 3600) / 60)
+    if (h > 0) return h + "h " + m + "m"
+    return m + "m"
+  }
+
+  function findBattery() {
+    for (var i = 0; i < UPower.devices.count; i++) {
+      var d = UPower.devices.get(i)
+      if (d.ready && d.isLaptopBattery) return d
+    }
+    if (UPower.displayDevice && UPower.displayDevice.ready)
+      return UPower.displayDevice
+    return null
+  }
+
+  function updateBattery() {
+    var dev = root.findBattery()
+    if (dev) {
+      root.batteryDevice = dev
+      root.pct = dev.percentage * 100
+      root.state = dev.state
+      var ch = dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge
+      root.charging = ch
+      if (ch) root.stateLabel = "Charging"
+      else if (dev.state === UPowerDeviceState.FullyCharged) root.stateLabel = "Fully charged"
+      else if (dev.state === UPowerDeviceState.Discharging) root.stateLabel = "Discharging"
+      else if (dev.state === UPowerDeviceState.PendingDischarge) root.stateLabel = "Pending discharge"
+      else if (dev.state === UPowerDeviceState.PendingCharge) root.stateLabel = "Pending charge"
+      else root.stateLabel = "Unknown"
+      if (ch && dev.timeToFull > 0) root.timeLabel = root.formatTime(dev.timeToFull) + " until full"
+      else if (!ch && dev.state === UPowerDeviceState.Discharging && dev.timeToEmpty > 0) root.timeLabel = root.formatTime(dev.timeToEmpty) + " remaining"
+      else root.timeLabel = ""
+    }
+  }
+
+  Process {
+    id: cycleQuery
+    command: ["cat", "/sys/class/power_supply/BAT0/cycle_count"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var c = text.trim()
+        if (c.length > 0 && !isNaN(c)) {
+          root.cycles = c
+        } else {
+          root.cycles = "--"
+        }
+      }
+    }
+  }
+
+  onVisibleChanged: {
+    if (visible) {
+      root.updateBattery()
+      cycleQuery.running = true
+    }
+  }
+
+  Column {
+    id: contentColumn
+    anchors {
+      fill: parent
+      margins: 12
+    }
+    spacing: 12
+
+    Text {
+      text: "Battery"
+      color: Colors.fgSurface
+      font.family: Config.fontFamily
+      font.pixelSize: (Config.fontPixelSize + 8)
+      font.weight: Font.Bold
+    }
+
+    PopupDivider {}
+
+    Row {
+      spacing: 12
+      Text {
+        text: root.pct >= 0 ? Math.round(root.pct) + "%" : "--%"
+        color: (root.pct <= 10 ? Colors.destructive : Colors.fgSurface)
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 16)
+        font.weight: Font.Bold
+      }
+      Column {
+        anchors.verticalCenter: parent.verticalCenter
+        spacing: 2
+        Text {
+          text: root.stateLabel
+          color: (root.charging ? Colors.primary : Colors.fgSurfaceVariant)
+          font.family: Config.fontFamily
+          font.pixelSize: (Config.fontPixelSize + 2)
+          font.weight: Font.Medium
+        }
+        Text {
+          text: root.batteryDevice && root.batteryDevice.energyCapacity ? root.batteryDevice.energyCapacity.toFixed(1) + " Wh" : ""
+          color: Colors.fgSurfaceVariant
+          font.family: Config.fontFamily
+          font.pixelSize: (Config.fontPixelSize + 1)
+        }
+      }
+    }
+
+    Rectangle {
+      width: parent.width
+      height: 10
+      radius: 5
+      color: Colors.surfaceContainerHighest
+      Rectangle {
+        anchors {
+          left: parent.left; top: parent.top; bottom: parent.bottom
+          leftMargin: 2; topMargin: 2; bottomMargin: 2
+        }
+        width: (parent.width - 4) * Math.max(0, Math.min(1, root.pct / 100))
+        radius: 3
+        color: root.pct < 0 ? "transparent" : (root.charging || root.pct > 20 ? (Colors.primary) : (Colors.warning))
+      }
+    }
+
+    Text {
+      text: root.timeLabel
+      color: Colors.fgSurfaceVariant
+      font.family: Config.fontFamily
+      font.pixelSize: (Config.fontPixelSize + 1)
+      visible: root.timeLabel !== ""
+    }
+
+    RowLayout {
+      width: parent.width
+      visible: root.batteryDevice !== null
+      spacing: 0
+
+      ColumnLayout {
+        Layout.fillWidth: true
+        spacing: 2
+        Text {
+          text: root.charging ? "Charge Rate" : "Discharge Rate"
+          color: Colors.fgSurfaceVariant
+          font.family: Config.fontFamily
+          font.pixelSize: (Config.fontPixelSize + 1)
+        }
+        Text {
+          text: root.batteryDevice && root.batteryDevice.changeRate !== undefined ? root.batteryDevice.changeRate.toFixed(1) + " W" : "-- W"
+          color: Colors.fgSurface
+          font.family: Config.fontFamily
+          font.pixelSize: (Config.fontPixelSize + 2)
+          font.weight: Font.Medium
+        }
+      }
+
+      ColumnLayout {
+        Layout.fillWidth: true
+        spacing: 2
+        Text {
+          text: "Cycle Count"
+          color: Colors.fgSurfaceVariant
+          font.family: Config.fontFamily
+          font.pixelSize: (Config.fontPixelSize + 1)
+        }
+        Text {
+          text: root.cycles
+          color: Colors.fgSurface
+          font.family: Config.fontFamily
+          font.pixelSize: (Config.fontPixelSize + 2)
+          font.weight: Font.Medium
+        }
+      }
+    }
+
+    Text {
+      text: root.batteryDevice ? root.batteryDevice.model || root.batteryDevice.vendor || "" : ""
+      color: Colors.fgSurfaceVariant
+      font.family: Config.fontFamily
+      font.pixelSize: (Config.fontPixelSize + 1)
+    }
+  }
+}
diff --git a/.config/quickshell/pill/surfaces/BrightnessSurface.qml b/.config/quickshell/pill/surfaces/BrightnessSurface.qml
new file mode 100644
index 00000000..562f64d4
--- /dev/null
+++ b/.config/quickshell/pill/surfaces/BrightnessSurface.qml
@@ -0,0 +1,94 @@
+import QtQuick
+import Quickshell
+import Quickshell.Io
+import "../components"
+import "../config"
+
+Item {
+  id: root
+
+  implicitHeight: contentColumn.implicitHeight + 32
+
+  property real pct: 0
+
+  function setBrightness(val) {
+    root.pct = Math.max(0, Math.min(100, val))
+    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pct) + "%"])
+  }
+
+  Process {
+    id: getProc
+    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var val = parseFloat(text.trim())
+        if (!isNaN(val)) root.pct = val
+      }
+    }
+  }
+
+  function pollBrightness() { getProc.running = true }
+
+  Process {
+    id: brightnessWatcher
+    command: ["sh", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness"]
+    running: root.visible
+    stdout: SplitParser {
+      onRead: function(data) { root.pollBrightness() }
+    }
+    onRunningChanged: {
+      if (!running && root.visible) brightnessWatcherRetry.start()
+    }
+  }
+
+  Timer {
+    id: brightnessWatcherRetry
+    interval: 1000
+    onTriggered: {
+      if (root.visible) brightnessWatcher.running = true
+    }
+  }
+
+  onVisibleChanged: if (visible) root.pollBrightness()
+
+  Column {
+    id: contentColumn
+    anchors {
+      fill: parent
+      margins: Config.popupPadding
+    }
+    spacing: 16
+
+    Text {
+      text: "Brightness"
+      color: Colors.fgSurface
+      font.family: Config.fontFamily
+      font.pixelSize: (Config.fontPixelSize + 8)
+      font.weight: Font.Bold
+    }
+
+    PopupDivider {}
+
+    Text {
+      text: Math.round(root.pct) + "%"
+      color: Colors.fgSurfaceVariant
+      font.family: Config.fontFamily
+      font.pixelSize: (Config.fontPixelSize + 4)
+    }
+
+    SliderControl {
+      value: root.pct / 100
+      activeColor: Colors.brightness
+      surfaceContainerHigh: Colors.surfaceContainerHigh
+      surfaceContainerHighest: Colors.surfaceContainerHighest
+      outline: Colors.outline
+      focusColor: Colors.brightness
+      motionDuration: Config.motionMedium
+      reducedMotion: Config.reducedMotion
+      accessibleName: "Brightness"
+      accessibleDescription: "Adjust display brightness"
+      onChanged: function(val) { root.setBrightness(val * 100) }
+    }
+  }
+}
diff --git a/.config/quickshell/pill/surfaces/BtSurface.qml b/.config/quickshell/pill/surfaces/BtSurface.qml
new file mode 100644
index 00000000..89bc05f7
--- /dev/null
+++ b/.config/quickshell/pill/surfaces/BtSurface.qml
@@ -0,0 +1,247 @@
+import QtQuick
+import QtQuick.Layouts
+import Quickshell
+import Quickshell.Io
+import "../components"
+import "../config"
+
+Item {
+  id: root
+
+  implicitHeight: contentColumn.implicitHeight + 24
+
+  property bool btOn: false
+
+  Process {
+    id: statusQuery
+    command: ["bluetoothctl", "show"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var out = text.trim()
+        root.btOn = out.indexOf("Powered: yes") >= 0
+        if (root.btOn) {
+          listQuery.running = true
+        } else {
+          btListModel.clear()
+        }
+      }
+    }
+  }
+
+  Process {
+    id: listQuery
+    command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | while read -r line; do MAC=$(echo \"$line\" | cut -d' ' -f2); NAME=$(echo \"$line\" | cut -d' ' -f3-); BATT=$(bluetoothctl info \"$MAC\" 2>/dev/null | grep \"Battery Percentage:\" | awk -F '[()]' '{print $2}'); if [ -n \"$BATT\" ]; then echo \"$MAC|||$NAME|||$BATT\"; else echo \"$MAC|||$NAME|||\"; fi; done"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var out = text.trim()
+        btListModel.clear()
+        if (out.length > 0) {
+          var lines = out.split("\n")
+          for (var i = 0; i < lines.length; i++) {
+            var parts = lines[i].split("|||")
+            if (parts.length >= 2) {
+              var macVal = parts[0]
+              var nameVal = parts[1]
+              var battVal = parts.length > 2 ? parts[2].trim() : ""
+              btListModel.append({ mac: macVal, name: nameVal, battery: battVal })
+            }
+          }
+        }
+      }
+    }
+  }
+
+  Timer {
+    id: refreshTimer
+    interval: 1000
+    repeat: false
+    onTriggered: statusQuery.running = true
+  }
+
+  onVisibleChanged: {
+    if (visible) statusQuery.running = true
+  }
+
+  Column {
+    id: contentColumn
+    anchors {
+      fill: parent
+      margins: 12
+    }
+    spacing: 12
+
+    RowLayout {
+      width: parent.width
+      spacing: 12
+
+      Text {
+        Layout.fillWidth: true
+        text: "Bluetooth"
+        color: Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 8)
+        font.weight: Font.Bold
+      }
+
+      IconButton {
+        iconLabel: "refresh"
+        size: 28
+        iconSize: 20
+        enabled: !listQuery.running
+        accessibleName: "Refresh Bluetooth devices"
+        tooltipText: "Refresh Bluetooth devices"
+        onClicked: listQuery.running = true
+      }
+
+      SwitchControl {
+        id: btSwitch
+        checked: root.btOn
+        activeColor: Colors.primary
+        surfaceContainerHighest: Colors.surfaceContainerHighest
+        outline: Colors.outline
+        motionDuration: Config.motionMedium
+        reducedMotion: Config.reducedMotion
+        accessibleName: "Bluetooth enabled"
+
+        onToggled: {
+          var newState = !root.btOn
+          Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"])
+          root.btOn = newState
+          refreshTimer.start()
+        }
+      }
+    }
+
+    PopupDivider {}
+
+    ColumnLayout {
+      width: parent.width
+      spacing: 8
+      visible: !root.btOn
+
+      Item {
+        Layout.preferredHeight: 12
+      }
+
+      Text {
+        Layout.alignment: Qt.AlignHCenter
+        text: "bluetooth_disabled"
+        color: Colors.fgSurfaceVariant
+        font.family: Config.iconFont
+        font.pixelSize: 48
+        opacity: 0.25
+      }
+
+      Text {
+        Layout.alignment: Qt.AlignHCenter
+        text: "Bluetooth is turned off"
+        color: Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 4)
+        font.weight: Font.Bold
+      }
+
+      Text {
+        Layout.alignment: Qt.AlignHCenter
+        text: "Enable Bluetooth to view connected devices."
+        color: Colors.fgSurfaceVariant
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 1)
+      }
+    }
+
+    ColumnLayout {
+      width: parent.width
+      spacing: 8
+      visible: root.btOn
+
+      ListModel {
+        id: btListModel
+      }
+
+      ListView {
+        id: listView
+        Layout.fillWidth: true
+        Layout.preferredHeight: Math.min(300, contentHeight)
+        model: btListModel
+        clip: true
+        spacing: 4
+        delegate: btItemDelegate
+        boundsBehavior: Flickable.StopAtBounds
+      }
+
+      Text {
+        Layout.fillWidth: true
+        text: "No connected devices found"
+        visible: btListModel.count === 0 && !listQuery.running
+        horizontalAlignment: Text.AlignHCenter
+        color: Colors.fgSurfaceVariant
+        font.family: Config.fontFamily
+        font.pixelSize: Config.fontPixelSize + 2
+      }
+    }
+  }
+
+  Component {
+    id: btItemDelegate
+
+    ListItem {
+      id: itemRow
+      width: listView.width
+      leadingIcon: "bluetooth"
+      leadingIconColor: Colors.primary
+      title: model.name
+      subtitle: model.mac
+      accessibleName: model.name + " Bluetooth device"
+
+      Row {
+        spacing: 4
+        anchors.verticalCenter: parent.verticalCenter
+        visible: model.battery !== "" && !itemRow.hovered
+
+        Text {
+          text: model.battery + "%"
+          color: Colors.primary
+          font.family: Config.fontFamily
+          font.pixelSize: Config.fontPixelSize + 1
+          font.weight: Font.Bold
+          anchors.verticalCenter: parent.verticalCenter
+        }
+
+        Text {
+          text: {
+            var b = parseInt(model.battery)
+            if (isNaN(b)) return "battery_unknown"
+            if (b <= 10) return "battery_alert"
+            if (b <= 20) return "battery_1_bar"
+            if (b <= 40) return "battery_2_bar"
+            if (b <= 60) return "battery_3_bar"
+            if (b <= 80) return "battery_4_bar"
+            if (b <= 95) return "battery_5_bar"
+            return "battery_full"
+          }
+          color: Colors.primary
+          font.family: Config.iconFont
+          font.pixelSize: 18
+          anchors.verticalCenter: parent.verticalCenter
+        }
+      }
+
+      IconButton {
+        size: 28
+        iconSize: 20
+        iconLabel: "link_off"
+        visible: itemRow.hovered
+        iconColor: Colors.error
+        accessibleName: "Disconnect " + model.name
+        tooltipText: accessibleName
+        onClicked: {
+          Quickshell.execDetached(["bluetoothctl", "disconnect", model.mac])
+          refreshTimer.start()
+        }
+      }
+    }
+  }
+}
diff --git a/.config/quickshell/pill/surfaces/WifiSurface.qml b/.config/quickshell/pill/surfaces/WifiSurface.qml
new file mode 100644
index 00000000..50c8d7de
--- /dev/null
+++ b/.config/quickshell/pill/surfaces/WifiSurface.qml
@@ -0,0 +1,434 @@
+import QtQuick
+import QtQuick.Layouts
+import Quickshell
+import Quickshell.Io
+import "../components"
+import "../config"
+
+Item {
+  id: root
+
+  implicitHeight: contentColumn.implicitHeight + 24
+
+  property bool wifiOn: false
+  property string wifiDevice: ""
+  property int selectedIndex: -1
+  property string statusMessage: ""
+  property bool connecting: false
+
+  function parseWifiList(output) {
+    var lines = output.trim().split("\n");
+    var list = [];
+    var seenSSIDs = {};
+    for (var i = 0; i < lines.length; i++) {
+      var line = lines[i];
+      if (!line) continue;
+
+      var parts = [];
+      var currentPart = "";
+      for (var j = 0; j < line.length; j++) {
+        var c = line[j];
+        if (c === ":" && (j === 0 || line[j-1] !== "\\")) {
+          parts.push(currentPart);
+          currentPart = "";
+        } else {
+          currentPart += c;
+        }
+      }
+      parts.push(currentPart);
+
+      if (parts.length < 4) continue;
+
+      var active = parts[0] === "yes";
+      var ssid = parts[1].replace(/\\(.)/g, "$1");
+      var signal = parseInt(parts[2]);
+      var security = parts[3];
+
+      if (!ssid || ssid === "") continue;
+
+      if (seenSSIDs[ssid] !== undefined) {
+        var existingIndex = seenSSIDs[ssid];
+        if (active) {
+          list[existingIndex].active = true;
+        }
+        if (signal > list[existingIndex].signal) {
+          list[existingIndex].signal = signal;
+          list[existingIndex].security = security;
+        }
+        continue;
+      }
+
+      list.push({
+        ssid: ssid,
+        signal: signal,
+        active: active,
+        security: security,
+        secured: !!(security && security.length > 0 && security !== "--")
+      });
+      seenSSIDs[ssid] = list.length - 1;
+    }
+
+    list.sort(function(a, b) {
+      if (a.active) return -1;
+      if (b.active) return 1;
+      return b.signal - a.signal;
+    });
+
+    return list;
+  }
+
+  function connectToNetwork(ssid, password, secured) {
+    root.connecting = true
+    root.statusMessage = "Connecting to " + ssid + "..."
+
+    var cmd = ""
+    if (secured && password.length > 0) {
+      cmd = "nmcli dev wifi connect '" + ssid.replace(/'/g, "'\\''") + "' password '" + password.replace(/'/g, "'\\''") + "' 2>&1"
+    } else {
+      cmd = "nmcli dev wifi connect '" + ssid.replace(/'/g, "'\\''") + "' 2>&1"
+    }
+
+    connectProcess.command = ["sh", "-c", cmd]
+    connectProcess.running = true
+  }
+
+  Process {
+    id: statusQuery
+    command: ["nmcli", "radio", "wifi"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        root.wifiOn = text.trim() === "enabled"
+        if (root.wifiOn) {
+          deviceQuery.running = true
+          listQuery.running = true
+        } else {
+          root.wifiDevice = ""
+        }
+      }
+    }
+  }
+
+  Process {
+    id: deviceQuery
+    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        root.wifiDevice = ""
+        var lines = text.trim().split("\n")
+        for (var i = 0; i < lines.length; i++) {
+          var parts = lines[i].split(":")
+          if (parts.length >= 3 && parts[1] === "wifi" && parts[2].indexOf("connected") === 0) {
+            root.wifiDevice = parts[0]
+            break
+          }
+        }
+      }
+    }
+  }
+
+  Process {
+    id: listQuery
+    command: ["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi", "list"]
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        var out = text.trim()
+        var parsed = root.parseWifiList(out)
+        wifiListModel.clear()
+        for (var i = 0; i < parsed.length; i++) {
+          wifiListModel.append(parsed[i])
+        }
+      }
+    }
+  }
+
+  Process {
+    id: connectProcess
+    running: false
+    stdout: StdioCollector {
+      onStreamFinished: {
+        root.connecting = false
+        var out = text.trim()
+        if (out.indexOf("successfully activated") >= 0) {
+          root.statusMessage = "Successfully connected!"
+          root.selectedIndex = -1
+          listQuery.running = true
+        } else {
+          root.statusMessage = "Connection failed: " + out
+        }
+      }
+    }
+  }
+
+  Timer {
+    id: refreshTimer
+    interval: 1000
+    repeat: false
+    onTriggered: statusQuery.running = true
+  }
+
+  onVisibleChanged: {
+    if (visible) {
+      statusQuery.running = true
+      deviceQuery.running = true
+      root.statusMessage = ""
+      root.selectedIndex = -1
+    }
+  }
+
+  Column {
+    id: contentColumn
+    anchors {
+      fill: parent
+      margins: 12
+    }
+    spacing: 12
+
+    RowLayout {
+      width: parent.width
+      spacing: 12
+
+      Text {
+        Layout.fillWidth: true
+        text: "Wi-Fi Networks"
+        color: Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 8)
+        font.weight: Font.Bold
+      }
+
+      IconButton {
+        iconLabel: "refresh"
+        size: 28
+        iconSize: 20
+        enabled: !listQuery.running
+        accessibleName: "Refresh Wi-Fi networks"
+        tooltipText: "Refresh Wi-Fi networks"
+        onClicked: listQuery.running = true
+      }
+
+      SwitchControl {
+        id: wifiSwitch
+        checked: root.wifiOn
+        activeColor: Colors.primary
+        surfaceContainerHighest: Colors.surfaceContainerHighest
+        outline: Colors.outline
+        motionDuration: Config.motionMedium
+        reducedMotion: Config.reducedMotion
+        accessibleName: "Wi-Fi enabled"
+
+        onToggled: {
+          var newState = !root.wifiOn
+          Quickshell.execDetached(["nmcli", "radio", "wifi", newState ? "on" : "off"])
+          root.wifiOn = newState
+          refreshTimer.start()
+        }
+      }
+    }
+
+    PopupDivider {}
+
+    ColumnLayout {
+      width: parent.width
+      spacing: 8
+      visible: !root.wifiOn
+
+      Item {
+        Layout.preferredHeight: 12
+      }
+
+      Text {
+        Layout.alignment: Qt.AlignHCenter
+        text: "wifi"
+        color: Colors.fgSurfaceVariant
+        font.family: Config.iconFont
+        font.pixelSize: 48
+        opacity: 0.25
+      }
+
+      Text {
+        Layout.alignment: Qt.AlignHCenter
+        text: "Wi-Fi is turned off"
+        color: Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 4)
+        font.weight: Font.Bold
+      }
+
+      Text {
+        Layout.alignment: Qt.AlignHCenter
+        text: "Enable Wi-Fi to scan and connect."
+        color: Colors.fgSurfaceVariant
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 1)
+      }
+    }
+
+    ColumnLayout {
+      width: parent.width
+      spacing: 8
+      visible: root.wifiOn
+
+      ListModel {
+        id: wifiListModel
+      }
+
+      ListView {
+        id: listView
+        Layout.fillWidth: true
+        Layout.preferredHeight: Math.min(300, contentHeight)
+        model: wifiListModel
+        clip: true
+        spacing: 4
+        delegate: wifiItemDelegate
+        boundsBehavior: Flickable.StopAtBounds
+      }
+
+      Text {
+        Layout.fillWidth: true
+        text: "No networks found"
+        visible: wifiListModel.count === 0 && !listQuery.running
+        horizontalAlignment: Text.AlignHCenter
+        color: Colors.fgSurfaceVariant
+        font.family: Config.fontFamily
+        font.pixelSize: Config.fontPixelSize + 2
+      }
+    }
+
+    Text {
+      text: root.statusMessage
+      color: Colors.primary
+      font.family: Config.fontFamily
+      font.pixelSize: Config.fontPixelSize + 1
+      wrapMode: Text.Wrap
+      width: parent.width
+      visible: root.statusMessage !== ""
+    }
+  }
+
+  Component {
+    id: wifiItemDelegate
+
+    Item {
+      id: delegateRoot
+      width: ListView.view.width
+      height: expanded ? 104 : 48
+      clip: true
+
+      readonly property bool expanded: root.selectedIndex === index
+      readonly property bool isCurrent: model.active
+
+      Behavior on height {
+        NumberAnimation {
+          duration: Config.motionMedium
+          easing.type: Easing.OutCubic
+        }
+      }
+
+      ListItem {
+        id: collapsedRow
+        width: parent.width
+        height: 44
+        radius: 8
+        leadingIcon: "wifi"
+        leadingIconColor: isCurrent ? Colors.primary : Colors.fgSurface
+        leadingIconOpacity: {
+          var sig = model.signal
+          if (sig <= 25) return 0.4
+          if (sig <= 50) return 0.6
+          if (sig <= 75) return 0.8
+          return 1.0
+        }
+        title: model.ssid
+        subtitle: isCurrent ? "Connected" : ""
+        selected: isCurrent
+        accessibleName: model.ssid + " Wi-Fi network"
+        accessibleDescription: isCurrent ? "Connected, signal " + model.signal + " percent" : "Signal " + model.signal + " percent"
+        onClicked: root.selectedIndex = (root.selectedIndex === index) ? -1 : index
+
+        Text {
+          text: model.signal + "%"
+          color: Colors.fgSurfaceVariant
+          font.family: Config.fontFamily
+          font.pixelSize: Config.fontPixelSize
+          Layout.alignment: Qt.AlignVCenter
+        }
+
+        Text {
+          text: "lock"
+          visible: model.secured
+          color: Colors.outline
+          font.family: Config.iconFont
+          font.pixelSize: 16
+          Layout.alignment: Qt.AlignVCenter
+        }
+      }
+
+      RowLayout {
+        anchors {
+          left: parent.left
+          right: parent.right
+          top: collapsedRow.bottom
+          topMargin: 8
+          leftMargin: 12
+          rightMargin: 12
+        }
+        visible: delegateRoot.expanded
+        spacing: 12
+
+        TextFieldControl {
+          id: passField
+          Layout.fillWidth: true
+          visible: model.secured
+          placeholder: "Password"
+          accessibleName: "Wi-Fi password"
+          echoMode: TextInput.Password
+        }
+
+        ActionButton {
+          Layout.fillWidth: !model.secured
+          Layout.preferredWidth: model.secured ? 88 : 0
+          Layout.preferredHeight: 36
+          radius: 18
+          variant: "filled"
+          labelText: isCurrent ? "Disconnect" : "Connect"
+          enabled: !root.connecting
+          accessibleName: labelText + " to " + model.ssid
+          onActivated: {
+            if (isCurrent) {
+              root.connecting = true
+              root.statusMessage = "Disconnecting..."
+              if (root.wifiDevice) {
+                disconnectProcess.command = ["nmcli", "device", "disconnect", root.wifiDevice]
+                disconnectProcess.running = true
+              } else {
+                root.connecting = false
+                root.statusMessage = "Could not determine the Wi-Fi device."
+                deviceQuery.running = true
+              }
+            } else {
+              root.connectToNetwork(model.ssid, passField.text, model.secured)
+            }
+          }
+        }
+      }
+    }
+  }
+
+  Process {
+    id: disconnectProcess
+    running: false
+    onExited: (exitCode) => {
+      root.connecting = false
+      if (exitCode === 0) {
+        root.statusMessage = "Disconnected successfully!"
+        listQuery.running = true
+        deviceQuery.running = true
+      } else {
+        root.statusMessage = "Disconnect failed."
+      }
+    }
+  }
+}
