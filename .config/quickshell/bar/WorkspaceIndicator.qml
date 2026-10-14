import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Niri (and mango) workspace state and actions for the top strip. No visuals:
// Bar.qml keeps it visible with zero size because its refreshers are gated on
// `visible`. `workspaces` is [{idx, isFocused, isOccupied}] sorted by idx.
Item {
  id: root

  property var workspaces: []
  property bool workspaceRefreshPending: false

  readonly property string wmType: Config.wmType
  readonly property bool compositorIntegration: Config.isNiri || Config.isMango

  Process {
    id: refresher
    command: root.wmType === "mango"
      ? ["mmsg", "get", "all-monitors"]
      : ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j workspaces"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text.trim())
          root.workspaces = root.wmType === "mango"
            ? root.parseMangoMonitorList(data)
            : root.parseWorkspaceList(data)
        } catch (e) { print("WorkspaceIndicator parse error:", e) }
      }
    }

    onRunningChanged: {
      if (!running && root.workspaceRefreshPending && root.visible) {
        workspaceRefreshDebounce.restart()
      }
    }
  }

  Timer {
    id: workspaceRefreshDebounce
    interval: 80
    repeat: false
    onTriggered: {
      if (!root.visible || !root.compositorIntegration) {
        root.workspaceRefreshPending = false
        return
      }
      if (refresher.running) return
      root.workspaceRefreshPending = false
      refresher.running = true
    }
  }

  function requestWorkspaceRefresh() {
    if (!root.visible || !root.compositorIntegration) return
    root.workspaceRefreshPending = true
    workspaceRefreshDebounce.restart()
  }

  Process {
    id: niriWatcher
    command: root.wmType === "mango"
      ? ["mmsg", "watch", "all-monitors"]
      : ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j event-stream"]
    running: root.visible && root.compositorIntegration

    stdout: SplitParser {
      onRead: function(data) {
        var raw = String(data).trim()
        if (!raw) return

        try {
          var event = JSON.parse(raw)
          if (root.wmType === "mango") {
            if (event && Array.isArray(event.monitors)) {
              root.workspaces = root.parseMangoMonitorList(event)
              root.workspaceRefreshPending = false
              workspaceRefreshDebounce.stop()
            } else {
              root.requestWorkspaceRefresh()
            }
            return
          }

          var workspaceEvent = event && event.WorkspacesChanged
          // Niri reports focus moves through these narrower events instead of
          // always sending a complete WorkspacesChanged snapshot.
          var workspaceStateChanged = event && (
            event.WorkspacesChanged
            || event.WorkspaceActivated
            || event.WorkspaceActiveWindowChanged
            || event.WindowFocusChanged
            || event.WindowsChanged
            || event.WindowClosed
          )
          if (workspaceEvent && Array.isArray(workspaceEvent.workspaces)) {
            root.workspaces = root.parseWorkspaceList(workspaceEvent.workspaces)
            root.workspaceRefreshPending = false
            workspaceRefreshDebounce.stop()
          } else if (workspaceStateChanged) {
            root.requestWorkspaceRefresh()
          }
        } catch (e) {
          root.requestWorkspaceRefresh()
        }
      }
    }

    onRunningChanged: {
      if (!running && root.compositorIntegration && root.visible) {
        niriWatcherRetry.start()
      }
    }
  }

  Timer {
    id: niriWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.compositorIntegration && root.visible) {
        niriWatcher.running = true
      }
    }
  }

  onVisibleChanged: {
    if (visible && root.compositorIntegration) requestWorkspaceRefresh()
  }

  Component.onCompleted: {
    if (root.visible && root.compositorIntegration) requestWorkspaceRefresh()
  }

  function parseWorkspaceList(data) {
    var list = []
    if (!Array.isArray(data)) return list

    for (var i = 0; i < data.length; i++) {
      list.push({
        idx: data[i].idx,
        isFocused: data[i].is_focused === true,
        isOccupied: data[i].active_window_id != null
      })
    }

    list.sort(function(a, b) { return a.idx - b.idx })
    return list
  }

  function parseMangoMonitorList(data) {
    var byIndex = ({})
    if (!data || !Array.isArray(data.monitors)) return []

    for (var monitorIndex = 0; monitorIndex < data.monitors.length; monitorIndex++) {
      var monitor = data.monitors[monitorIndex]
      if (!monitor || !Array.isArray(monitor.tags)) continue
      for (var tagIndex = 0; tagIndex < monitor.tags.length; tagIndex++) {
        var tag = monitor.tags[tagIndex]
        var idx = Number(tag && tag.index)
        if (!isFinite(idx) || idx < 1) continue

        if (!byIndex[idx]) {
          byIndex[idx] = { idx: idx, isFocused: false, isOccupied: false }
        }
        byIndex[idx].isFocused = byIndex[idx].isFocused || tag.is_active === true
        byIndex[idx].isOccupied = byIndex[idx].isOccupied
          || Number(tag.client_count || 0) > 0
      }
    }

    var list = []
    for (var key in byIndex) list.push(byIndex[key])
    list.sort(function(a, b) { return a.idx - b.idx })
    return list
  }

  function focusWorkspace(idx) {
    if (root.wmType === "mango")
      Quickshell.execDetached(["mmsg", "dispatch", "view," + idx])
    else
      Quickshell.execDetached(["sh", "-c", "niri msg action focus-workspace " + idx])
  }

  // Her right click: move the focused window to workspace `idx` without
  // following it.
  function moveFocusedWindowTo(idx) {
    if (root.wmType === "mango") return
    Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", "--focus", "false", String(idx)])
  }

  // Her wheel: -1 previous (up), +1 next (down).
  function stepWorkspace(direction) {
    root.scrollWorkspace(direction < 0 ? 1 : -1)
  }

  function scrollWorkspace(deltaY) {
    if (root.wmType === "mango") {
      Quickshell.execDetached([
        "mmsg",
        "dispatch",
        deltaY > 0 ? "viewtoleft_have_client,0" : "viewtoright_have_client,0"
      ])
    } else if (deltaY > 0) {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"])
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"])
    }
  }
}
