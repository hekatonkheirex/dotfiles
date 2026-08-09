## Commits
c539ca69 Fork StatusIndicator and the 4 rest-row Indicators into pill/components/

## Diffstat
 .../pill/components/BatteryIndicator.qml           |  46 ++++++
 .../pill/components/BrightnessIndicator.qml        |  84 +++++++++++
 .config/quickshell/pill/components/BtIndicator.qml |  65 +++++++++
 .../quickshell/pill/components/StatusIndicator.qml | 161 +++++++++++++++++++++
 .../quickshell/pill/components/WifiIndicator.qml   |  66 +++++++++
 5 files changed, 422 insertions(+)

## Full diff
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
