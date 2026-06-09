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

  readonly property string wmType: {
    var desktop = Quickshell.env("XDG_CURRENT_DESKTOP")
    if (desktop && desktop.toLowerCase() === "niri") return "niri"
    var niriSock = Quickshell.env("NIRI_SOCKET")
    if (niriSock && niriSock.length > 0) return "niri"
    var sig = Quickshell.env("MANGO_INSTANCE_SIGNATURE")
    if (sig && sig.length > 0) return "mango"
    return "niri"
  }

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: workspaces.length * pillHeight + (workspaces.length - 1) * 6

  Timer {
    id: refreshTimer
    interval: root.wmType === "mango" ? 500 : 1000
    running: true
    repeat: true
    onTriggered: {
      if (!refresher.running) refresher.running = true
    }
  }

  Process {
    id: refresher
    command: root.wmType === "mango"
      ? ["mmsg", "get", "all-tags"]
      : ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j workspaces"]
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
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg event-stream | head -1"]
    running: root.wmType === "niri"
    onRunningChanged: {
      if (!running && root.wmType === "niri") {
        refresher.running = true
        running = true
      }
    }
  }

  function parseWorkspaces(text) {
    var data = JSON.parse(text)
    var list = []

    if (root.wmType === "mango") {
      var monitors = data.all_tags
      if (monitors && monitors.length > 0) {
        var tags = monitors[0].tags
        for (var i = 0; i < tags.length; i++) {
          list.push({
            idx: tags[i].index,
            isFocused: tags[i].is_active === true,
            isOccupied: tags[i].client_count > 0
          })
        }
      }
    } else {
      for (var i = 0; i < data.length; i++) {
        list.push({
          idx: data[i].idx,
          isFocused: data[i].is_focused,
          isOccupied: data[i].active_window_id != null
        })
      }
    }

    if (root.wmType === "mango")
      list = list.filter(function(t) { return t.isFocused || t.isOccupied })
    list.sort(function(a, b) { return a.idx - b.idx })
    return list
  }

  function focusWorkspace(idx) {
    if (root.wmType === "mango") {
      Quickshell.execDetached(["mmsg", "dispatch", "view," + idx])
    } else {
      Quickshell.execDetached(["sh", "-c", "niri msg action focus-workspace " + idx])
    }
  }

  function scrollWorkspace(deltaY) {
    if (root.wmType === "mango") {
      if (deltaY > 0)
        Quickshell.execDetached(["mmsg", "dispatch", "viewtoleft"])
      else
        Quickshell.execDetached(["mmsg", "dispatch", "viewtoright"])
    } else {
      if (deltaY > 0)
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"])
      else
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"])
    }
  }

  Column {
    anchors {
      fill: parent
      topMargin: 6
    }
    spacing: 6

    Repeater {
      model: root.workspaces

      delegate: Item {
        required property var modelData
        width: parent.width
        height: root.pillHeight

        Rectangle {
          anchors {
            fill: parent
            leftMargin: 6
            rightMargin: 6
          }
          radius: (width) / 2
          color: {
            if (modelData.isFocused) return colors_ ? (colors_.darkMode ? colors_.primary : colors_.primaryContainer) : "#D0BCFF"
            if (wsMouse.containsMouse) return colors_ ? colors_.surfaceContainerHighest : "#3A3840"
            if (modelData.isOccupied) return colors_ ? colors_.surfaceContainerHigh : "#2B2930"
            return "transparent"
          }
          border.width: modelData.isFocused ? 0 : 1
          border.color: {
            if (modelData.isFocused) return "transparent"
            return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, modelData.isOccupied ? 0.3 : 0.15) : Qt.rgba(147/255, 143/255, 153/255, modelData.isOccupied ? 0.3 : 0.15)
          }

          Behavior on color {
            ColorAnimation { duration: config ? config.animationDuration : 150 }
          }

          Text {
            anchors.centerIn: parent
            text: modelData.idx.toString()
            color: {
              if (modelData.isFocused) return colors_ ? colors_.onPrimary : "#FFFFFF"
              if (modelData.isOccupied) return colors_ ? colors_.onSurface : "#FFFFFF"
              return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.5) : Qt.rgba(147/255, 143/255, 153/255, 0.5)
            }
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 4) : 14
            font.weight: modelData.isFocused ? Font.Bold : Font.Normal
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
