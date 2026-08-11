import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

Item {
  id: root

  property bool horizontal: false

  signal clicked(var mouse)

  property var workspaces: []
  property string focusedWindowTitle: ""
  property string focusedWindowAppId: ""
  readonly property string focusedWindowInfo: focusedWindowTitle !== "" ? focusedWindowTitle : focusedWindowAppId
  readonly property string focusedWindowProgram: formatProgramName(focusedWindowAppId)

  readonly property string wmType: Config.wmType

  implicitWidth: horizontal ? grid.implicitWidth + 12 : (Config.widgetSize)
  implicitHeight: horizontal ? (Config.widgetSize) : grid.implicitHeight + 12

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
    id: focusedWindowQuery
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j focused-window"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var raw = text.trim()
        if (!raw || raw === "null") {
          root.focusedWindowTitle = ""
          root.focusedWindowAppId = ""
          return
        }

        try {
          var data = JSON.parse(raw)
          var title = data && typeof data.title === "string" ? data.title : ""
          root.focusedWindowTitle = title.replace(/\s+/g, " ").trim()
          root.focusedWindowAppId = data && typeof data.app_id === "string" ? data.app_id : ""
        } catch (e) {
          root.focusedWindowTitle = ""
          root.focusedWindowAppId = ""
        }
      }
    }
  }

  Timer {
    id: focusedWindowRefreshDebounce
    interval: 80
    repeat: false
    onTriggered: {
      if (!focusedWindowQuery.running) focusedWindowQuery.running = true
    }
  }

  Process {
    id: niriWatcher
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg event-stream"]
    running: root.visible && root.wmType === "niri"

    stdout: SplitParser {
      onRead: function(data) {
        if (!refresher.running) refresher.running = true
        focusedWindowRefreshDebounce.restart()
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
        focusedWindowQuery.running = true
      }
    }
  }

  Component.onCompleted: {
    if (root.visible) {
      if (root.wmType === "niri") {
        refresher.running = true
        focusedWindowQuery.running = true
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

  function formatProgramName(appId) {
    var knownNames = ({
      "kitty": "Kitty",
      "brave-origin": "Brave",
      "brave-browser": "Brave",
      "firefox": "Firefox",
      "chromium": "Chromium",
      "code": "VS Code",
      "pavucontrol": "PulseAudio Volume Control"
    })

    if (!appId) return ""
    if (knownNames[appId]) return knownNames[appId]

    var words = appId.replace(/[._-]+/g, " ").split(" ")
    for (var i = 0; i < words.length; i++) {
      if (words[i].length > 0) {
        words[i] = words[i].charAt(0).toUpperCase() + words[i].slice(1)
      }
    }
    return words.join(" ")
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

  Grid {
    id: grid
    columns: root.horizontal ? Math.max(1, root.workspaces.length) : 1
    anchors {
      left: parent.left
      right: root.horizontal ? undefined : parent.right
      top: parent.top
      bottom: root.horizontal ? parent.bottom : undefined
      leftMargin: root.horizontal ? 6 : 0
      topMargin: root.horizontal ? 0 : 6
    }
    spacing: 2

    Repeater {
      model: root.workspaces

      delegate: Item {
        id: delegateItem
        required property var modelData

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: "Workspace " + modelData.idx
        Accessible.description: modelData.isFocused
          ? "Focused workspace"
          : (modelData.isOccupied ? "Occupied workspace" : "Empty workspace")

        readonly property bool active: modelData.isFocused || wsMouse.containsMouse

        width: root.horizontal ? (active ? 40 : 12) : grid.width
        height: root.horizontal ? grid.height : (active ? 40 : 12)
        Behavior on width {
          NumberAnimation {
            duration: Config.animationDuration
            easing.type: Easing.OutBack
          }
        }
        Behavior on height {
          NumberAnimation {
            duration: Config.animationDuration
            easing.type: Easing.OutBack
          }
        }

        Rectangle {
          id: pillRect
          anchors.centerIn: parent
          width: delegateItem.active ? (root.horizontal ? Math.min(32, delegateItem.width - 4) : 10) : (root.horizontal ? (modelData.isOccupied ? 10 : 6) : 4)
          height: delegateItem.active ? (root.horizontal ? 10 : Math.min(32, delegateItem.height - 4)) : (root.horizontal ? 4 : (modelData.isOccupied ? 10 : 6))
          radius: delegateItem.active ? Math.min(width, height) / 2 : 2

          color: {
            if (modelData.isFocused) return Colors.primary
            var base = modelData.isOccupied ? Colors.surfaceContainerHighest : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)
            return Qt.tint(base, wsMouse.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
          }
          border.width: modelData.isFocused ? 0 : 1
          border.color: {
            if (modelData.isFocused) return "transparent"
            return Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, modelData.isOccupied ? 0.3 : 0.1)
          }

          Behavior on width {
            NumberAnimation { duration: Config.animationDuration; easing.type: Easing.OutBack }
          }
          Behavior on height {
            NumberAnimation { duration: Config.animationDuration; easing.type: Easing.OutBack }
          }
          Behavior on color {
            ColorAnimation { duration: Config.animationDuration}
          }
        }

        MouseArea {
          id: wsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            delegateItem.forceActiveFocus()
            root.clicked(null)
            root.focusWorkspace(modelData.idx)
          }
          onWheel: function(wheel) {
            wheel.accepted = true
            root.scrollWorkspace(wheel.angleDelta.y)
          }
        }

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked(null)
            root.focusWorkspace(modelData.idx)
            event.accepted = true
          }
        }
      }
    }
  }
}
