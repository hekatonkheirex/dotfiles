// Wi-Fi content for the Settings Network tab. Lifted out of the old
// standalone Wi-Fi popup.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

Item {
  id: root

  implicitHeight: contentColumn.implicitHeight

  property bool wifiOn: false
  property string wifiDevice: ""
  property int selectedIndex: -1
  property string statusMessage: ""
  property bool connecting: false
  property bool statusKnown: false
  property bool unavailable: false
  property string pendingDeleteConnection: ""

  ListModel {
    id: savedListModel
  }

  function refresh() {
    statusQuery.running = true
    deviceQuery.running = true
    root.statusKnown = false
    root.unavailable = false
    root.statusMessage = "Checking Wi-Fi..."
    root.selectedIndex = -1
    savedQuery.running = true
  }

  function setUnavailable(message) {
    root.statusKnown = true
    root.unavailable = true
    root.wifiOn = false
    root.wifiDevice = ""
    root.selectedIndex = -1
    root.connecting = false
    root.pendingDeleteConnection = ""
    root.statusMessage = message
    wifiListModel.clear()
    savedListModel.clear()
  }

  function parseWifiList(output) {
    var lines = output.trim().split("\n");
    var list = [];
    var seenSSIDs = {};
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (!line) continue;

      var parts = [];
      var currentPart = "";
      for (var j = 0; j < line.length; j++) {
        var c = line[j];
        if (c === ":" && (j === 0 || line[j-1] !== "\\")) {
          parts.push(currentPart);
          currentPart = "";
        } else {
          currentPart += c;
        }
      }
      parts.push(currentPart);

      if (parts.length < 4) continue;

      var active = parts[0] === "yes";
      var ssid = parts[1].replace(/\\(.)/g, "$1");
      var signal = parseInt(parts[2]);
      var security = parts[3];

      if (!ssid || ssid === "") continue;

      if (seenSSIDs[ssid] !== undefined) {
        var existingIndex = seenSSIDs[ssid];
        if (active) {
          list[existingIndex].active = true;
        }
        if (signal > list[existingIndex].signal) {
          list[existingIndex].signal = signal;
          list[existingIndex].security = security;
        }
        continue;
      }

      list.push({
        ssid: ssid,
        signal: signal,
        active: active,
        security: security,
        secured: !!(security && security.length > 0 && security !== "--")
      });
      seenSSIDs[ssid] = list.length - 1;
    }

    list.sort(function(a, b) {
      if (a.active) return -1;
      if (b.active) return 1;
      return b.signal - a.signal;
    });

    return list;
  }

  function connectToNetwork(ssid, password, secured) {
    root.connecting = true
    root.statusMessage = "Connecting to " + ssid + "..."

    var cmd = ""
    if (secured && password.length > 0) {
      cmd = "nmcli dev wifi connect '" + ssid.replace(/'/g, "'\\''") + "' password '" + password.replace(/'/g, "'\\''") + "' 2>&1"
    } else {
      cmd = "nmcli dev wifi connect '" + ssid.replace(/'/g, "'\\''") + "' 2>&1"
    }

    connectProcess.command = ["sh", "-c", cmd]
    connectProcess.running = true
  }

  function setAutoconnect(name, enabled) {
    savedModifyProcess.command = ["nmcli", "connection", "modify", name, "connection.autoconnect", enabled ? "yes" : "no"]
    savedModifyProcess.running = true
  }

  function requestForget(name) {
    if (name) root.pendingDeleteConnection = name
  }

  function forgetConnection() {
    if (!root.pendingDeleteConnection) return
    savedDeleteProcess.command = ["nmcli", "connection", "delete", root.pendingDeleteConnection]
    savedDeleteProcess.running = true
  }

  Process {
    id: statusQuery
    command: ["nmcli", "radio", "wifi"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        if (out !== "enabled" && out !== "disabled") {
          root.setUnavailable("Wi-Fi controls unavailable. NetworkManager did not return a status.")
          return
        }

        root.statusKnown = true
        root.unavailable = false
        root.statusMessage = ""
        root.wifiOn = out === "enabled"
        if (root.wifiOn) {
          deviceQuery.running = true
          listQuery.running = true
        } else {
          root.wifiDevice = ""
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0) root.setUnavailable("Wi-Fi controls unavailable. NetworkManager is not responding.")
    }
  }

  Process {
    id: deviceQuery
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.wifiDevice = ""
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(":")
          if (parts.length >= 3 && parts[1] === "wifi" && parts[2].indexOf("connected") === 0) {
            root.wifiDevice = parts[0]
            break
          }
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0 && root.statusKnown && !root.unavailable) {
        root.statusMessage = "Could not determine the active Wi-Fi device."
      }
    }
  }

  Process {
    id: listQuery
    command: ["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi", "list"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var parsed = root.parseWifiList(out)
        wifiListModel.clear()
        for (var i = 0; i < parsed.length; i++) {
          wifiListModel.append(parsed[i])
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0 && root.statusKnown && !root.unavailable) {
        wifiListModel.clear()
        root.statusMessage = "Could not scan for Wi-Fi networks."
      }
    }
  }

  Process {
    id: savedQuery
    command: ["nmcli", "-t", "-e", "no", "-f", "NAME,TYPE,AUTOCONNECT,DEVICE", "connection", "show"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        savedListModel.clear()
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(":")
          if (parts.length < 4 || parts[1] !== "802-11-wireless") continue
          savedListModel.append({
            name: parts[0],
            autoconnect: parts[2] === "yes",
            active: parts[3] !== "--"
          })
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0 && root.statusKnown && !root.unavailable) savedListModel.clear()
    }
  }

  Process {
    id: savedModifyProcess
    running: false
    onExited: (exitCode) => {
      root.statusMessage = exitCode === 0 ? "Saved network updated." : "Could not update saved network."
      savedQuery.running = true
    }
  }

  Process {
    id: savedDeleteProcess
    running: false
    onExited: (exitCode) => {
      root.statusMessage = exitCode === 0 ? "Saved network forgotten." : "Could not forget saved network."
      root.pendingDeleteConnection = ""
      savedQuery.running = true
    }
  }

  Process {
    id: connectProcess
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.connecting = false
        var out = text.trim()
        if (out.indexOf("successfully activated") >= 0) {
          root.statusMessage = "Successfully connected!"
          root.selectedIndex = -1
          listQuery.running = true
        } else {
          root.statusMessage = out.length > 0 ? "Connection failed: " + out : "Connection failed."
        }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 1000
    repeat: false
    onTriggered: statusQuery.running = true
  }

  Column {
    id: contentColumn
    width: parent.width
    spacing: 12

    RowLayout {
      width: parent.width
      spacing: 12

      Item { Layout.fillWidth: true }

      IconButton {
        iconLabel: "refresh"
        size: 28
        iconSize: 20
        enabled: !listQuery.running
        accessibleName: "Refresh Wi-Fi networks"
        tooltipText: "Refresh Wi-Fi networks"
        onClicked: root.refresh()
      }

      SwitchControl {
        id: wifiSwitch
        checked: root.wifiOn
        activeColor: Colors.primary
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.outline
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Wi-Fi enabled"
        enabled: root.statusKnown && !root.unavailable

        onToggled: {
          var newState = !root.wifiOn
          Quickshell.execDetached(["nmcli", "radio", "wifi", newState ? "on" : "off"])
          root.wifiOn = newState
          refreshTimer.start()
        }
      }
    }

    ColumnLayout {
      width: parent.width
      spacing: 8
      visible: !root.statusKnown

      Item { Layout.preferredHeight: 12 }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "sync"
        color: Colors.fgSurfaceVariant
        font.family: Config.iconFont
        font.pixelSize: 48
        opacity: 0.25
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Checking Wi-Fi status"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 4
        font.weight: Font.Bold
      }
    }

    ColumnLayout {
      width: parent.width
      spacing: 8
      visible: root.unavailable

      Item { Layout.preferredHeight: 12 }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "wifi_off"
        color: Colors.error
        font.family: Config.iconFont
        font.pixelSize: 48
        opacity: 0.75
      }

      Text {
        Layout.fillWidth: true
        text: "Wi-Fi unavailable"
        horizontalAlignment: Text.AlignHCenter
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 4
        font.weight: Font.Bold
      }

      Text {
        Layout.fillWidth: true
        text: "NetworkManager is unavailable or returned an error."
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 1
      }
    }

    // Wi-Fi is Off
    ColumnLayout {
      width: parent.width
      spacing: 8
      visible: root.statusKnown && !root.unavailable && !root.wifiOn

      Item {
        Layout.preferredHeight: 12
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "wifi"
        color: Colors.fgSurfaceVariant
        font.family: Config.iconFont
        font.pixelSize: 48
        opacity: 0.25
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Wi-Fi is turned off"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize + 4)
        font.weight: Font.Bold
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Enable Wi-Fi to scan and connect."
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize + 1)
      }
    }

    // Wi-Fi is On: list networks
    ColumnLayout {
      width: parent.width
      spacing: 8
      visible: root.statusKnown && !root.unavailable && root.wifiOn

      ListModel {
        id: wifiListModel
      }

      ListView {
        id: listView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(300, contentHeight)
        model: wifiListModel
        clip: true
        spacing: 4
        delegate: wifiItemDelegate
        boundsBehavior: Flickable.StopAtBounds
      }

      Text {
        Layout.fillWidth: true
        text: "No networks found"
        visible: wifiListModel.count === 0 && !listQuery.running
        horizontalAlignment: Text.AlignHCenter
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 2
      }
    }

    ColumnLayout {
      width: parent.width
      spacing: Config.spacingSmall
      visible: root.statusKnown && !root.unavailable && savedListModel.count > 0

      Text {
        text: "Saved Networks"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textCaptionSize
        font.weight: Font.Medium
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(240, contentHeight)
        model: savedListModel
        clip: true
        spacing: Config.spacingCompact
        boundsBehavior: Flickable.StopAtBounds

        delegate: ListItem {
          width: ListView.view.width
          leadingIcon: model.active ? "wifi" : "wifi_find"
          leadingIconColor: model.active ? Colors.primary : Colors.fgSurface
          title: model.name
          subtitle: model.active ? "Connected" : "Saved network"
          accessibleName: model.name + " saved Wi-Fi network"

          SwitchControl {
            checked: model.autoconnect
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Autoconnect to " + model.name
            onToggled: root.setAutoconnect(model.name, !model.autoconnect)
          }

          IconButton {
            size: 28
            iconSize: 18
            iconLabel: "delete"
            iconColor: Colors.error
            accessibleName: "Forget " + model.name
            tooltipText: "Forget saved network"
            onClicked: root.requestForget(model.name)
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      visible: root.pendingDeleteConnection !== ""
      spacing: Config.spacingSmall

      Text {
        Layout.fillWidth: true
        text: "Forget “" + root.pendingDeleteConnection + "”?"
        color: Colors.error
        font.family: Config.fontFamily
        font.pixelSize: Config.textBodySize
        elide: Text.ElideRight
      }

      ActionButton {
        Layout.preferredWidth: 72
        Layout.preferredHeight: 36
        labelText: "Forget"
        variant: "filled"
        accessibleName: "Confirm forget saved network"
        onActivated: root.forgetConnection()
      }

      ActionButton {
        Layout.preferredWidth: 72
        Layout.preferredHeight: 36
        labelText: "Cancel"
        variant: "quiet"
        accessibleName: "Cancel forget saved network"
        onActivated: root.pendingDeleteConnection = ""
      }
    }

    Text {
      text: root.statusMessage
      color: Colors.primary
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize + 1
      wrapMode: Text.Wrap
      width: parent.width
      visible: root.statusMessage !== ""
    }
  }

  Component {
    id: wifiItemDelegate

    Item {
      id: delegateRoot
      width: ListView.view.width
      height: expanded ? 104 : 48
      clip: true

      readonly property bool expanded: root.selectedIndex === index
      readonly property bool isCurrent: model.active

      Behavior on height {
        NumberAnimation {
          duration: Config.motionMedium
          easing.type: Easing.OutCubic
        }
      }

      ListItem {
        id: collapsedRow
        width: parent.width
        height: 44
        radius: 8
        leadingIcon: "wifi"
        leadingIconColor: isCurrent ? Colors.primary : Colors.fgSurface
        leadingIconOpacity: {
          var sig = model.signal
          if (sig <= 25) return 0.4
          if (sig <= 50) return 0.6
          if (sig <= 75) return 0.8
          return 1.0
        }
        title: model.ssid
        subtitle: isCurrent ? "Connected" : ""
        selected: isCurrent
        accessibleName: model.ssid + " Wi-Fi network"
        accessibleDescription: isCurrent ? "Connected, signal " + model.signal + " percent" : "Signal " + model.signal + " percent"
        onClicked: root.selectedIndex = (root.selectedIndex === index) ? -1 : index

        Text {
          text: model.signal + "%"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize
          Layout.alignment: Qt.AlignVCenter
        }

        Text {
          text: "lock"
          visible: model.secured
          color: Colors.outline
          font.family: Config.iconFont
          font.pixelSize: 16
          Layout.alignment: Qt.AlignVCenter
        }
      }

      RowLayout {
        anchors {
          left: parent.left
          right: parent.right
          top: collapsedRow.bottom
          topMargin: 8
          leftMargin: 12
          rightMargin: 12
        }
        visible: delegateRoot.expanded
        spacing: 12

        TextFieldControl {
          id: passField
          Layout.fillWidth: true
          visible: model.secured
          placeholder: "Password"
          accessibleName: "Wi-Fi password"
          echoMode: TextInput.Password
        }

        ActionButton {
          Layout.fillWidth: !model.secured
          Layout.preferredWidth: model.secured ? 88 : 0
          Layout.preferredHeight: 36
          radius: 18
          variant: "filled"
          labelText: isCurrent ? "Disconnect" : "Connect"
          enabled: !root.connecting
          accessibleName: labelText + " to " + model.ssid
          onActivated: {
            if (isCurrent) {
              root.connecting = true
              root.statusMessage = "Disconnecting..."
              if (root.wifiDevice) {
                disconnectProcess.command = ["nmcli", "device", "disconnect", root.wifiDevice]
                disconnectProcess.running = true
              } else {
                root.connecting = false
                root.statusMessage = "Could not determine the Wi-Fi device."
                deviceQuery.running = true
              }
            } else {
              root.connectToNetwork(model.ssid, passField.text, model.secured)
            }
          }
        }
      }
    }
  }

  Process {
    id: disconnectProcess
    running: false
    onExited: (exitCode) => {
      root.connecting = false
      if (exitCode === 0) {
        root.statusMessage = "Disconnected successfully!"
        listQuery.running = true
        deviceQuery.running = true
      } else {
        root.statusMessage = "Disconnect failed."
      }
    }
  }
}
