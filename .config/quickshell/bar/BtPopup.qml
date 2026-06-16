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
  property bool horizontal: false

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  property bool btOn: false

  Process {
    id: statusQuery
    command: ["bluetoothctl", "show"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        root.btOn = out.indexOf("Powered: yes") >= 0
        if (root.btOn) {
          listQuery.running = true
        } else {
          btListModel.clear()
        }
      }
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
        Translate { id: transY; y: 0 },
        Scale { id: scaleTransform; origin.x: root.horizontal ? bg.width / 2 : 0; origin.y: root.horizontal ? 0 : bg.height / 2; xScale: 1.0; yScale: 1.0 }
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
          from: root.horizontal ? 0 : -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transY
          property: "y"
          from: root.horizontal ? -30 : 0
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
            text: "Bluetooth"
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
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
            id: btSwitch
            checked: root.btOn
            activeColor: colors_ ? colors_.primary : "#D0BCFF"
            surfaceContainerHighest: colors_ ? colors_.surfaceContainerHighest : "#36343B"
            outline: colors_ ? colors_.outline : "#938F99"
            checkmarkColor: colors_ ? (colors_.darkMode ? colors_.fgPrimary : colors_.primary) : "#0F3C2C"
            
            onToggled: {
              var newState = !root.btOn
              Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"])
              root.btOn = newState
              refreshTimer.start()
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
        }

        // Bluetooth is Off
        ColumnLayout {
          width: parent.width
          spacing: 8
          visible: !root.btOn

          Item {
            Layout.preferredHeight: 12
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "bluetooth_disabled"
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 48
            opacity: 0.25
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bluetooth is turned off"
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 4) : 14
            font.weight: Font.Bold
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enable Bluetooth to view connected devices."
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 1) : 11
          }
        }

        // Bluetooth is On
        ColumnLayout {
          width: parent.width
          spacing: 8
          visible: root.btOn

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
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? config.fontPixelSize + 2 : 12
          }
        }
      }
    }
  }

  Component {
    id: btItemDelegate

    Rectangle {
      id: itemRow
      width: listView.width
      height: 48
      radius: 12
      color: colors_ ? (itemMouse.containsMouse ? colors_.surfaceContainerHighest : "transparent") : (itemMouse.containsMouse ? "#36343B" : "transparent")

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Text {
          text: "bluetooth"
          color: colors_ ? colors_.primary : "#D0BCFF"
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: 22
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.fillWidth: true
            text: model.name
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 3) : 13
            font.weight: Font.Medium
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            text: model.mac
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize) : 10
            elide: Text.ElideRight
          }
        }

        Row {
          spacing: 4
          Layout.alignment: Qt.AlignVCenter
          visible: model.battery !== "" && !itemMouse.containsMouse

          Text {
            text: model.battery + "%"
            color: colors_ ? colors_.primary : "#D0BCFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? config.fontPixelSize + 1 : 11
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
            color: colors_ ? colors_.primary : "#D0BCFF"
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Text {
          text: "link_off"
          color: colors_ ? colors_.error : "#F2B8B5"
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: 20
          visible: itemMouse.containsMouse
          
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Quickshell.execDetached(["bluetoothctl", "disconnect", model.mac])
              refreshTimer.start()
            }
          }
        }
      }

      MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
      }
    }
  }
}
