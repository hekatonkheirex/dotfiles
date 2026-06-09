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
  implicitHeight: Math.min(clipItem.implicitHeight + 32, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(10, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  ListModel { id: appModel }
  ListModel { id: filteredModel }

  property string searchText: ""
  property int selectedIndex: 0

  Process {
    id: desktopProc
    command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/bin/desktop-parser.py"]
    running: false

    stdout: StdioCollector {
      id: stdoutCollector
      onStreamFinished: {
        var txt = text
        if (txt.length > 0) {
          try {
            var json = JSON.parse(txt)
            for (var i = 0; i < json.length; i++) {
              appModel.append(json[i])
            }
            if (visible) filterApps()
          } catch (e) { print("LauncherPopup parse error:", e) }
        }
      }
    }
  }

  Component.onCompleted: {
    desktopProc.running = true
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible && config && config.isNiri) root.dismissed()
    })
  }

  function sanitizeExec(cmd) {
    return cmd.replace(/%[fFuUdDnNickvm]/g, "").trim()
  }

  function launchApp(execCmd, terminal) {
    var cmd = sanitizeExec(execCmd)
    if (terminal) {
      Quickshell.execDetached(["sh", "-c", "kitty -e " + cmd])
    } else {
      Quickshell.execDetached(["sh", "-c", cmd + " &"])
    }
    dismissed()
  }

  function filterApps() {
    filteredModel.clear()
    var q = searchText.toLowerCase().trim()
    for (var i = 0; i < appModel.count; i++) {
      var app = appModel.get(i)
      if (q === "" || app.name.toLowerCase().indexOf(q) !== -1 || app.comment.toLowerCase().indexOf(q) !== -1) {
        filteredModel.append(app)
      }
    }
    selectedIndex = Math.max(0, Math.min(selectedIndex, filteredModel.count - 1))
  }

  Timer {
    id: focusTimer
    interval: 1
    running: visible
    onTriggered: searchInput.forceActiveFocus()
  }

  Timer {
    id: focusCheck
    interval: 300
    running: visible
    repeat: true
    onTriggered: {
      if (!searchInput.activeFocus) {
        stop()
        dismissed()
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      searchInput.text = ""
      searchText = ""
      selectedIndex = 0
      filteredModel.clear()
      if (appModel.count > 0) {
        for (var i = 0; i < appModel.count; i++) {
          filteredModel.append(appModel.get(i))
        }
      }
      if (config && config.isNiri) root.requestActivate()
    }
  }

  Rectangle {
    anchors.fill: parent
    color: colors_ ? colors_.surfaceContainer : "#211F26"
    radius: 12
    border.color: colors_ ? colors_.outlineVariant : "#49454F"
    border.width: 1

    ColumnLayout {
      id: clipItem
      anchors { fill: parent; margins: 12 }
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "search"
          color: colors_ ? colors_.onSurfaceVariant : "#CAC4D0"
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: config ? (config.iconSize - 2) : 20
        }

        TextInput {
          id: searchInput
          Layout.fillWidth: true
          color: colors_ ? colors_.onSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: 17
          clip: true
          focus: true
          cursorVisible: true
          activeFocusOnPress: true

          onTextChanged: {
            root.searchText = text
            root.selectedIndex = 0
            filterApps()
          }

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              dismissed()
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (filteredModel.count > 0 && selectedIndex >= 0 && selectedIndex < filteredModel.count) {
                var app = filteredModel.get(selectedIndex)
                root.launchApp(app.exec, app.terminal)
              }
            } else if (event.key === Qt.Key_Up) {
              selectedIndex = Math.max(0, selectedIndex - 1)
              ensureVisible(selectedIndex)
            } else if (event.key === Qt.Key_Down) {
              selectedIndex = Math.min(filteredModel.count - 1, selectedIndex + 1)
              ensureVisible(selectedIndex)
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: colors_ ? colors_.outlineVariant : "#49454F"
      }

      ListView {
        id: appList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 380)
        model: filteredModel
        clip: true
        currentIndex: root.selectedIndex

        delegate: Rectangle {
          width: appList.width
          height: 44
          radius: 8
          color: root.selectedIndex === index ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent"

          RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: 10

            Rectangle {
              width: 30
              height: 30
              radius: 6
              color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"

              Image {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: model.icon !== "" ? "file://" + model.icon : ""
                sourceSize.width: 22
                sourceSize.height: 22
                smooth: true
                fillMode: Image.PreserveAspectFit
                visible: model.icon !== ""
              }

              Text {
                anchors.centerIn: parent
                text: model.name.charAt(0).toUpperCase()
                color: colors_ ? colors_.onSurface : "#FFFFFF"
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 15
                font.weight: Font.Medium
                visible: model.icon === ""
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                Layout.fillWidth: true
                text: model.name
                color: colors_ ? colors_.onSurface : "#FFFFFF"
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                text: model.comment || ""
                color: colors_ ? colors_.onSurfaceVariant : "#CAC4D0"
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 13
                elide: Text.ElideRight
                visible: text !== ""
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectedIndex = index
              root.launchApp(model.exec, model.terminal)
            }
            onEntered: { root.selectedIndex = index }
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }

  function ensureVisible(idx) {
    appList.positionViewAtIndex(idx, ListView.Contain)
  }
}
