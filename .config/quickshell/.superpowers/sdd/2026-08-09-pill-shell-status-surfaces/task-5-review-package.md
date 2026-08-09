## Commits
99c261a7 Port the wifi popup content into a pill-hosted WifiSurface

## Diffstat
 .config/quickshell/pill/surfaces/WifiSurface.qml | 434 +++++++++++++++++++++++
 1 file changed, 434 insertions(+)

## Full diff
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
