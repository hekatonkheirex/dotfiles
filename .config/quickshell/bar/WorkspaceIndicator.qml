import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  signal clicked(var mouse)

  property var workspaces: []
  property int pillHeight: 48

  readonly property string wmType: config ? config.wmType : "niri"

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: column.implicitHeight + 12

  Process {
    id: refresher
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j workspaces"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var list = parseWorkspaces(text.trim())
          root.workspaces = list
        } catch (e) { print("WorkspaceIndicator parse error:", e) }
      }
    }
  }

  Process {
    id: niriWatcher
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg event-stream"]
    running: root.visible && root.wmType === "niri"
    
    stdout: SplitParser {
      onRead: function(data) {
        if (!refresher.running) refresher.running = true
      }
    }

    onRunningChanged: {
      if (!running && root.wmType === "niri" && root.visible) {
        niriWatcherRetry.start()
      }
    }
  }

  Timer {
    id: niriWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.wmType === "niri" && root.visible) {
        niriWatcher.running = true
      }
    }
  }



  onVisibleChanged: {
    if (visible) {
      if (root.wmType === "niri") {
        refresher.running = true
      }
    }
  }

  Component.onCompleted: {
    if (root.visible) {
      if (root.wmType === "niri") {
        refresher.running = true
      }
    }
  }

  function parseWorkspaces(text) {
    var data = JSON.parse(text)
    var list = []

    for (var i = 0; i < data.length; i++) {
      list.push({
        idx: data[i].idx,
        isFocused: data[i].is_focused,
        isOccupied: data[i].active_window_id != null
      })
    }

    list.sort(function(a, b) { return a.idx - b.idx })
    return list
  }

  function focusWorkspace(idx) {
    Quickshell.execDetached(["sh", "-c", "niri msg action focus-workspace " + idx])
  }

  function scrollWorkspace(deltaY) {
    if (deltaY > 0)
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"])
    else
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"])
  }

  Column {
    id: column
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      topMargin: 6
    }
    spacing: 6

    Repeater {
      model: root.workspaces

      delegate: Item {
        id: delegateItem
        required property var modelData
        width: parent.width

        readonly property bool active: modelData.isFocused || wsMouse.containsMouse

        height: active ? 40 : 20
        Behavior on height {
          NumberAnimation {
            duration: config ? config.animationDuration : 150
            easing.type: Easing.OutBack
          }
        }

        Rectangle {
          id: pillRect
          anchors.centerIn: parent
          width: delegateItem.active ? 32 : (modelData.isOccupied ? 12 : 6)
          height: delegateItem.active ? 40 : (modelData.isOccupied ? 12 : 6)
          radius: height / 2

          color: {
            if (modelData.isFocused) return colors_ ? (colors_.darkMode ? colors_.primary : colors_.primaryContainer) : "#D0BCFF"
            if (wsMouse.containsMouse) return colors_ ? colors_.outlineVariant : "#49454F"
            if (modelData.isOccupied) return colors_ ? colors_.surfaceContainerHighest : "#3C3A43"
            return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.2) : Qt.rgba(147/255, 143/255, 153/255, 0.2)
          }
          border.width: modelData.isFocused ? 0 : 1
          border.color: {
            if (modelData.isFocused) return "transparent"
            return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, modelData.isOccupied ? 0.3 : 0.1) : Qt.rgba(147/255, 143/255, 153/255, modelData.isOccupied ? 0.3 : 0.1)
          }

          Behavior on width {
            NumberAnimation { duration: config ? config.animationDuration : 150; easing.type: Easing.OutBack }
          }
          Behavior on height {
            NumberAnimation { duration: config ? config.animationDuration : 150; easing.type: Easing.OutBack }
          }
          Behavior on color {
            ColorAnimation { duration: config ? config.animationDuration : 150 }
          }

          Text {
            anchors.centerIn: parent
            text: modelData.idx.toString()
            opacity: delegateItem.active ? 1.0 : 0.0
            visible: opacity > 0
            color: {
              if (modelData.isFocused) return colors_ ? colors_.fgPrimary : "#FFFFFF"
              return colors_ ? colors_.fgSurface : "#FFFFFF"
            }
            font.family: config ? config.fontFamily : "Roboto"
            font.pixelSize: config ? (config.fontPixelSize + 4) : 14
            font.weight: modelData.isFocused ? Font.Bold : Font.Normal

            Behavior on opacity {
              NumberAnimation { duration: 100 }
            }
          }
        }

        MouseArea {
          id: wsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.clicked(null)
            root.focusWorkspace(modelData.idx)
          }
          onWheel: function(wheel) {
            wheel.accepted = true
            root.scrollWorkspace(wheel.angleDelta.y)
          }
        }
      }
    }
  }
}
