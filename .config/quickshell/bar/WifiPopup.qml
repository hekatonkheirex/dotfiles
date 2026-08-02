import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  visible: false
  implicitHeight: Math.min(contentColumn.implicitHeight + 24, 450)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  property bool wifiOn: false
  property string wifiDevice: ""
  property int selectedIndex: -1
  property string statusMessage: ""
  property bool connecting: false

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

  Process {
    id: statusQuery
    command: ["nmcli", "radio", "wifi"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.wifiOn = text.trim() === "enabled"
        if (root.wifiOn) {
          deviceQuery.running = true
          listQuery.running = true
        } else {
          root.wifiDevice = ""
        }
      }
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
          root.statusMessage = "Connection failed: " + out
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

  onVisibleChanged: {
    if (visible) {
      statusQuery.running = true
      deviceQuery.running = true
      root.statusMessage = ""
      root.selectedIndex = -1
      entryAnimation.start()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      config: root.config
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true
      border.width: 1
      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: 12
        }
        spacing: 12

        RowLayout {
          width: parent.width
          spacing: 12

          Text {
            Layout.fillWidth: true
            text: "Wi-Fi Networks"
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? (config.fontPixelSize + 8) : 18
            font.weight: Font.Bold
          }

          Text {
            text: "refresh"
            color: colors_ ? colors_.primary : "#D0BCFF"
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 20
            opacity: listQuery.running ? 0.5 : 1.0
            
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              enabled: !listQuery.running
              onClicked: {
                listQuery.running = true
              }
            }
          }

          SwitchControl {
            id: wifiSwitch
            checked: root.wifiOn
            activeColor: colors_ ? colors_.primary : "#D0BCFF"
            surfaceContainerHighest: colors_ ? colors_.surfaceContainerHighest : "#36343B"
            outline: colors_ ? colors_.outline : "#938F99"
            checkmarkColor: colors_ ? (colors_.darkMode ? colors_.fgPrimary : colors_.primary) : "#0F3C2C"
            
            onToggled: {
              var newState = !root.wifiOn
              Quickshell.execDetached(["nmcli", "radio", "wifi", newState ? "on" : "off"])
              root.wifiOn = newState
              refreshTimer.start()
            }
          }
        }

        // Wi-Fi is Off Screen
        ColumnLayout {
          width: parent.width
          spacing: 8
          visible: !root.wifiOn

          Item {
            Layout.preferredHeight: 12
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "wifi"
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 48
            opacity: 0.25
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Wi-Fi is turned off"
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? (config.fontPixelSize + 4) : 14
            font.weight: Font.Bold
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enable Wi-Fi to scan and connect."
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? (config.fontPixelSize + 1) : 11
          }
        }

        // Wi-Fi is On: list networks
        ColumnLayout {
          width: parent.width
          spacing: 8
          visible: root.wifiOn

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
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? config.fontPixelSize + 2 : 12
          }
        }

        Text {
          text: root.statusMessage
          color: colors_ ? colors_.primary : "#D0BCFF"
          font.family: config ? config.fontFamily : "Roboto"
          font.pixelSize: config ? config.fontPixelSize + 1 : 11
          wrapMode: Text.Wrap
          width: parent.width
          visible: root.statusMessage !== ""
        }
      }
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
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: 8
        color: isCurrent
          ? (colors_ ? Qt.rgba(colors_.primary.r, colors_.primary.g, colors_.primary.b, 0.15) : Qt.rgba(208/255, 188/255, 255/255, 0.15))
          : (delegateMouse.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent")
        border.color: isCurrent ? (colors_ ? colors_.primary : "#D0BCFF") : "transparent"
        border.width: 1
      }

      RowLayout {
        id: collapsedRow
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          topMargin: 2
          leftMargin: 12
          rightMargin: 12
        }
        height: 44
        spacing: 12

        // Reserved space checkmark container to keep layout aligned
        Item {
          id: checkContainer
          Layout.preferredWidth: config ? config.iconSize : 20
          Layout.preferredHeight: config ? config.iconSize : 20
          Layout.alignment: Qt.AlignVCenter

          Text {
            anchors.centerIn: parent
            text: "check"
            visible: isCurrent
            color: colors_ ? colors_.primary : "#D0BCFF"
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: config ? config.iconSize : 20
          }
        }

        Text {
          text: "wifi"
          color: isCurrent ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.fgSurface : "#FFFFFF")
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: config ? config.iconSize : 20
          Layout.alignment: Qt.AlignVCenter
          opacity: {
            var sig = model.signal
            if (sig <= 25) return 0.4
            if (sig <= 50) return 0.6
            if (sig <= 75) return 0.8
            return 1.0
          }
        }

        // Two-line title + connection status layout
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          Layout.alignment: Qt.AlignVCenter

          Text {
            Layout.fillWidth: true
            text: model.ssid
            color: isCurrent ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.fgSurface : "#FFFFFF")
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? config.fontPixelSize + 2 : 12
            font.weight: isCurrent ? Font.Bold : Font.Normal
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            text: "Connected"
            visible: isCurrent
            color: colors_ ? colors_.primary : "#D0BCFF"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? config.fontPixelSize : 10
            font.weight: Font.Medium
          }
        }

        Text {
          text: model.signal + "%"
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Roboto"
          font.pixelSize: config ? config.fontPixelSize : 10
          Layout.alignment: Qt.AlignVCenter
        }

        Text {
          text: "lock"
          visible: model.secured
          color: colors_ ? colors_.outline : "#938F99"
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: 16
          Layout.alignment: Qt.AlignVCenter
        }
      }

      MouseArea {
        id: delegateMouse
        anchors.fill: collapsedRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.selectedIndex = (root.selectedIndex === index) ? -1 : index
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

        Rectangle {
          Layout.fillWidth: true
          height: 36
          radius: 8
          color: colors_ ? colors_.surface : "#211F26"
          border.color: passInput.activeFocus ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.outline : "#49454F")
          border.width: passInput.activeFocus ? 2 : 1
          visible: model.secured

          TextInput {
            id: passInput
            anchors {
              fill: parent
              leftMargin: 10
              rightMargin: 10
            }
            verticalAlignment: TextInput.AlignVCenter
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? config.fontPixelSize + 2 : 12
            echoMode: TextInput.Password

            Text {
              text: "Password"
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              visible: !parent.text && !parent.activeFocus
              font: parent.font
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        Rectangle {
          Layout.preferredWidth: model.secured ? 80 : parent.width
          Layout.preferredHeight: 36
          radius: 18
          color: colors_ ? colors_.primary : "#D0BCFF"
          opacity: root.connecting ? 0.6 : 1.0

          Text {
            anchors.centerIn: parent
            text: isCurrent ? "Disconnect" : "Connect"
            color: colors_ ? colors_.fgPrimary : "#0F3C2C"
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? config.fontPixelSize + 1 : 11
            font.weight: Font.Bold
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !root.connecting
            onClicked: {
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
                root.connectToNetwork(model.ssid, passInput.text, model.secured)
              }
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
