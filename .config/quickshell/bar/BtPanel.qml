// Bluetooth content for the Settings Bluetooth tab. Lifted out of the old
// standalone Bluetooth popup.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

Item {
  id: root

  implicitHeight: contentColumn.implicitHeight

  property bool btOn: false
  property bool discoverable: false
  property bool scanning: false
  property string renameMac: ""
  property string statusMessage: ""
  property bool statusKnown: false
  property bool unavailable: false

  ListModel {
    id: scanListModel
  }

  function refresh() {
    statusQuery.running = true
    root.statusKnown = false
    root.unavailable = false
    root.statusMessage = "Checking Bluetooth..."
  }

  function setUnavailable(message) {
    root.statusKnown = true
    root.unavailable = true
    root.btOn = false
    root.discoverable = false
    root.scanning = false
    root.renameMac = ""
    root.statusMessage = message
    btListModel.clear()
    scanListModel.clear()
  }

  Process {
    id: statusQuery
    command: ["bluetoothctl", "show"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var poweredYes = out.indexOf("Powered: yes") >= 0
        var poweredNo = out.indexOf("Powered: no") >= 0
        if (!poweredYes && !poweredNo) {
          root.setUnavailable("Bluetooth controls unavailable. No controller status was returned.")
          return
        }

        root.statusKnown = true
        root.unavailable = false
        root.statusMessage = ""
        root.btOn = poweredYes
        root.discoverable = out.indexOf("Discoverable: yes") >= 0
        if (root.btOn) {
          listQuery.running = true
        } else {
          btListModel.clear()
          scanListModel.clear()
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0) root.setUnavailable("Bluetooth controls unavailable. bluetoothctl is not responding.")
    }
  }

  Process {
    id: listQuery
    command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | while read -r line; do MAC=$(echo \"$line\" | cut -d' ' -f2); NAME=$(echo \"$line\" | cut -d' ' -f3-); BATT=$(bluetoothctl info \"$MAC\" 2>/dev/null | grep \"Battery Percentage:\" | awk -F '[()]' '{print $2}'); if [ -n \"$BATT\" ]; then echo \"$MAC|||$NAME|||$BATT\"; else echo \"$MAC|||$NAME|||\"; fi; done"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        btListModel.clear()
        if (out.length > 0) {
          var lines = out.split("\n")
          for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("|||")
            if (parts.length >= 2) {
              var macVal = parts[0]
              var nameVal = parts[1]
              var battVal = parts.length > 2 ? parts[2].trim() : ""
              btListModel.append({ mac: macVal, name: nameVal, battery: battVal })
            }
          }
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0 && root.statusKnown && !root.unavailable) {
        btListModel.clear()
        root.statusMessage = "Could not read connected Bluetooth devices."
      }
    }
  }

  Process {
    id: scanProcess
    command: ["sh", "-c", "timeout 8 bluetoothctl scan on >/dev/null 2>&1; bluetoothctl devices 2>/dev/null"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.scanning = false
        scanListModel.clear()
        var lines = text.trim().split("\n")
        var seen = {}
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].trim().split(" ")
          if (parts.length < 3 || parts[0] !== "Device") continue
          var mac = parts[1]
          if (seen[mac]) continue
          seen[mac] = true
          scanListModel.append({ mac: mac, name: parts.slice(2).join(" ") })
        }
        root.statusMessage = scanListModel.count > 0
          ? "Found " + scanListModel.count + " nearby device(s)."
          : "No nearby Bluetooth devices found."
      }
    }
    onExited: (exitCode) => {
      root.scanning = false
      if (exitCode !== 0 && root.statusKnown && !root.unavailable) root.statusMessage = "Bluetooth scan failed."
    }
  }

  Process {
    id: pairProcess
    running: false
    onExited: (exitCode) => {
      root.statusMessage = exitCode === 0 ? "Pairing completed." : "Pairing failed. Check the device and try again."
      refreshTimer.start()
    }
  }

  Process {
    id: renameProcess
    running: false
    onExited: (exitCode) => {
      root.statusMessage = exitCode === 0 ? "Bluetooth device renamed." : "Could not rename Bluetooth device."
      root.renameMac = ""
      refreshTimer.start()
    }
  }

  Timer {
    id: refreshTimer
    interval: 1000
    repeat: false
    onTriggered: statusQuery.running = true
  }

  function scanDevices() {
    if (!root.btOn || root.scanning) return
    root.scanning = true
    root.statusMessage = "Scanning for Bluetooth devices..."
    scanProcess.running = false
    scanProcess.running = true
  }

  function pairDevice(mac) {
    if (!mac || pairProcess.running) return
    root.statusMessage = "Pairing with " + mac + "..."
    pairProcess.command = ["bluetoothctl", "pair", mac]
    pairProcess.running = true
  }

  function startRename(mac, name) {
    root.renameMac = mac
    renameField.input.text = name
    renameField.input.forceActiveFocus()
  }

  function renameDevice() {
    var name = renameField.input.text.trim()
    if (!root.renameMac || name === "") return
    root.statusMessage = "Renaming Bluetooth device..."
    renameProcess.command = ["bluetoothctl", "set-alias", root.renameMac, name]
    renameProcess.running = true
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
        accessibleName: "Refresh Bluetooth devices"
        tooltipText: "Refresh Bluetooth devices"
        onClicked: root.refresh()
      }

      IconButton {
        iconLabel: "bluetooth_searching"
        size: 28
        iconSize: 20
        enabled: root.btOn && !root.scanning
        accessibleName: "Scan for Bluetooth devices"
        tooltipText: "Scan for Bluetooth devices"
        onClicked: root.scanDevices()
      }

      SwitchControl {
        id: btSwitch
        checked: root.btOn
        activeColor: Colors.primary
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Bluetooth enabled"
        enabled: root.statusKnown && !root.unavailable

        onToggled: {
          var newState = !root.btOn
          Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"])
          root.btOn = newState
          refreshTimer.start()
        }
      }
    }

    ListItem {
      width: parent.width
      visible: root.statusKnown && !root.unavailable && root.btOn
      leadingIcon: "visibility"
      title: "Discoverable"
      subtitle: root.discoverable ? "Nearby devices can find this computer" : "Hidden from nearby devices"
      SwitchControl {
        checked: root.discoverable
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Bluetooth discoverable"
        onToggled: {
          var next = !root.discoverable
          Quickshell.execDetached(["bluetoothctl", "discoverable", next ? "on" : "off"])
          root.discoverable = next
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
        text: "Checking Bluetooth status"
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
        text: "bluetooth_disabled"
        color: Colors.error
        font.family: Config.iconFont
        font.pixelSize: 48
        opacity: 0.75
      }

      Text {
        Layout.fillWidth: true
        text: "Bluetooth unavailable"
        horizontalAlignment: Text.AlignHCenter
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 4
        font.weight: Font.Bold
      }

      Text {
        Layout.fillWidth: true
        text: "bluetoothctl is unavailable or returned an error."
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 1
      }
    }

    // Bluetooth is Off
    ColumnLayout {
      width: parent.width
      spacing: 8
      visible: root.statusKnown && !root.unavailable && !root.btOn

      Item {
        Layout.preferredHeight: 12
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "bluetooth_disabled"
        color: Colors.fgSurfaceVariant
        font.family: Config.iconFont
        font.pixelSize: 48
        opacity: 0.25
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Bluetooth is turned off"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize + 4)
        font.weight: Font.Bold
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Enable Bluetooth to view connected devices."
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize + 1)
      }
    }

    // Bluetooth is On
    ColumnLayout {
      width: parent.width
      spacing: 8
      visible: root.statusKnown && !root.unavailable && root.btOn

      ListModel {
        id: btListModel
      }

      ListView {
        id: listView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(300, contentHeight)
        model: btListModel
        clip: true
        spacing: 4
        delegate: btItemDelegate
        boundsBehavior: Flickable.StopAtBounds
      }

      Text {
        Layout.fillWidth: true
        text: "No connected devices found"
        visible: btListModel.count === 0 && !listQuery.running
        horizontalAlignment: Text.AlignHCenter
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontPixelSize + 2
      }
    }

    ColumnLayout {
      width: parent.width
      spacing: Config.spacingSmall
      visible: root.statusKnown && !root.unavailable && root.btOn && (root.scanning || scanListModel.count > 0)

      Text {
        text: root.scanning ? "Scanning..." : "Nearby Devices"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textCaptionSize
        font.weight: Font.Medium
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(240, contentHeight)
        model: scanListModel
        clip: true
        spacing: Config.spacingCompact
        boundsBehavior: Flickable.StopAtBounds

        delegate: ListItem {
          width: ListView.view.width
          leadingIcon: "bluetooth"
          title: model.name
          subtitle: model.mac
          accessibleName: "Pair with " + model.name
          IconButton {
            size: 28
            iconSize: 18
            iconLabel: "link"
            accessibleName: "Pair with " + model.name
            tooltipText: "Pair device"
            onClicked: root.pairDevice(model.mac)
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      visible: root.renameMac !== ""
      spacing: Config.spacingSmall

      TextFieldControl {
        id: renameField
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        placeholder: "New device name"
        accessibleName: "New Bluetooth device name"
      }

      ActionButton {
        Layout.preferredWidth: 72
        Layout.preferredHeight: 36
        labelText: "Save"
        variant: "filled"
        accessibleName: "Save Bluetooth device name"
        onActivated: root.renameDevice()
      }
    }

    Text {
      width: parent.width
      text: root.statusMessage
      color: Colors.primary
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize + 1
      wrapMode: Text.Wrap
      visible: root.statusMessage !== ""
    }
  }

  Component {
    id: btItemDelegate

    ListItem {
      id: itemRow
      width: listView.width
      leadingIcon: "bluetooth"
      leadingIconColor: Colors.primary
      title: model.name
      subtitle: model.mac
      accessibleName: model.name + " Bluetooth device"

      Item {
        id: deviceActionArea
        width: 60
        height: 32
        anchors.verticalCenter: parent.verticalCenter
        readonly property bool showActions: itemRow.hovered || disconnectButton.hovered || renameButton.hovered

        Row {
          spacing: 4
          anchors.centerIn: parent
          visible: model.battery !== "" && !deviceActionArea.showActions

          Text {
            text: model.battery + "%"
            color: Colors.primary
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 1
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: {
              var b = parseInt(model.battery)
              if (isNaN(b)) return "battery_unknown"
              if (b <= 10) return "battery_alert"
              if (b <= 20) return "battery_1_bar"
              if (b <= 40) return "battery_2_bar"
              if (b <= 60) return "battery_3_bar"
              if (b <= 80) return "battery_4_bar"
              if (b <= 95) return "battery_5_bar"
              return "battery_full"
            }
            color: Colors.primary
            font.family: Config.iconFont
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Row {
          spacing: 4
          anchors.centerIn: parent
          visible: deviceActionArea.showActions

          IconButton {
            id: disconnectButton
            size: 28
            iconSize: 20
            iconLabel: "link_off"
            iconColor: Colors.error
            accessibleName: "Disconnect " + model.name
            tooltipText: accessibleName
            onClicked: {
              Quickshell.execDetached(["bluetoothctl", "disconnect", model.mac])
              refreshTimer.start()
            }
          }

          IconButton {
            id: renameButton
            size: 28
            iconSize: 20
            iconLabel: "edit"
            iconColor: Colors.primary
            accessibleName: "Rename " + model.name
            tooltipText: accessibleName
            onClicked: root.startRename(model.mac, model.name)
          }
        }
      }
    }
  }
}
