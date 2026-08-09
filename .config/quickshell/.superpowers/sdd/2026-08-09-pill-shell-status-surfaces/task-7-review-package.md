## Commits
c366ea53 Wire battery, brightness, wifi, bluetooth surfaces into Pill.qml and shell.qml

## Diffstat
 .config/quickshell/pill/Pill.qml  | 89 +++++++++++++++++++++++++++++++++++++--
 .config/quickshell/pill/shell.qml |  4 ++
 2 files changed, 90 insertions(+), 3 deletions(-)

## Full diff
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
