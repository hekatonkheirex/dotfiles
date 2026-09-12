import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"
import "primitives"

Item {
  id: root

  property bool horizontal: false
  property bool integrated: false

  signal clicked(var mouse)

  property var workspaces: []
  property bool workspaceRefreshPending: false
  property bool focusedWindowRefreshPending: false
  property string focusedWindowTitle: ""
  property string focusedWindowAppId: ""
  property string mangoLayoutSymbol: ""
  readonly property string mangoLayoutName: layoutNameForMangoToken(mangoLayoutSymbol)
  readonly property string focusedWindowInfo: focusedWindowTitle !== "" ? focusedWindowTitle : focusedWindowAppId
  readonly property string focusedWindowProgram: formatProgramName(focusedWindowAppId)
  readonly property color workspaceGroupColor: Settings.themeStyle === "material3"
    && Colors.fixedPaletteActive
    && Settings.colorPalette === "tokyonight"
    ? Colors.surfaceContainer
    : Colors.surfaceContainerHighest

  readonly property string wmType: Config.wmType
  readonly property bool compositorIntegration: Config.isNiri || Config.isMango
  // Keep the existing shape values as stable preference tokens while also
  // accepting the marker styles exposed by Ryoku's workspace control.
  readonly property var workspaceStyleValues: [
    "expressive", "pill", "rounded", "circle", "dots", "numbers",
    "magic", "kanji", "rings", "aurora", "pacman"
  ]
  readonly property string workspaceStyle: workspaceStyleValues.indexOf(Settings.workspaceShape) >= 0
    ? Settings.workspaceShape
    : "expressive"
  // Compatibility name for the original four shape bindings.
  readonly property string workspaceShape: workspaceStyle
  readonly property string workspaceCount: ["active", "5", "10"].indexOf(Settings.workspaceCount) >= 0
    ? Settings.workspaceCount
    : "active"

  // Fixed ranges create the familiar 1..5 or 1..10 targets even when Niri has
  // not materialized an empty workspace yet. Keep the focused workspace visible
  // when it is outside that range so the current location is never ambiguous.
  readonly property var visibleWorkspaces: {
    var current = root.workspaces || []
    if (root.workspaceCount === "active") return current

    var limit = root.workspaceCount === "5" ? 5 : 10
    var result = []
    for (var idx = 1; idx <= limit; idx++) {
      var match = null
      for (var i = 0; i < current.length; i++) {
        if (current[i].idx === idx) {
          match = current[i]
          break
        }
      }
      result.push(match || { idx: idx, isFocused: false, isOccupied: false })
    }

    for (var j = 0; j < current.length; j++) {
      if (current[j].isFocused && current[j].idx > limit) {
        result.push(current[j])
        break
      }
    }
    return result
  }

  readonly property bool legacyWorkspaceShape: ["expressive", "pill", "rounded", "circle"].indexOf(root.workspaceStyle) >= 0

  function workspaceMarkerFill(item) {
    if (item.isFocused) return Colors.styleAccent
    if (item.isOccupied) return Qt.rgba(Colors.styleAccent.r, Colors.styleAccent.g, Colors.styleAccent.b, 0.24)
    return Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.14)
  }

  function workspaceMarkerColor(item) {
    return item.isFocused || item.isOccupied
      ? Colors.styleAccent
      : Colors.styleOutlineStrong
  }

  function workspaceMarkerTextColor(item) {
    if (item.isFocused) return Colors.styleAccentText
    if (item.isOccupied) return Colors.fgSurface
    return Qt.rgba(Colors.fgSurfaceVariant.r, Colors.fgSurfaceVariant.g, Colors.fgSurfaceVariant.b, 0.68)
  }

  function numberedWorkspaceFill(item) {
    if (item.isFocused)
      return Colors.styleAccent
    return "transparent"
  }

  function numberedWorkspaceTextColor(item) {
    if (item.isFocused)
      return Colors.styleAccentText
    return Colors.fgSurfaceVariant
  }

  function numberedWorkspaceWidth(item) {
    return item.isFocused || item.isOccupied ? 40 : 34
  }

  function numberedWorkspaceHeight(item) {
    var available = Math.max(22, Config.widgetSize - Config.spacingSmall)
    return item.isFocused || item.isOccupied
      ? Math.min(34, available)
      : Math.min(28, available)
  }

  readonly property int numberedVerticalWidth: Math.max(
    22,
    Math.min(30, Config.widgetSize - Config.spacingSmall - Config.spacingCompact)
  )

  implicitWidth: horizontal ? grid.implicitWidth + 12 : (Config.widgetSize)
  implicitHeight: horizontal ? (Config.widgetSize) : grid.implicitHeight + 12

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
          var list = root.wmType === "mango"
            ? root.parseMangoMonitorList(data)
            : root.parseWorkspaceList(data)
          root.workspaces = list
          if (root.wmType === "mango") root.applyMangoMonitorSnapshot(data)
        } catch (e) { print("WorkspaceIndicator parse error:", e) }
      }
    }

    onRunningChanged: {
      if (!running && root.workspaceRefreshPending && root.visible) {
        workspaceRefreshDebounce.restart()
      }
    }
  }

  Process {
    id: focusedWindowQuery
    command: root.wmType === "mango"
      ? ["mmsg", "get", "focusing-client"]
      : ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j focused-window"]
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
          root.focusedWindowAppId = data && typeof data.app_id === "string"
            ? data.app_id
            : (data && typeof data.appid === "string" ? data.appid : "")
        } catch (e) {
          root.focusedWindowTitle = ""
          root.focusedWindowAppId = ""
        }
      }
    }

    onRunningChanged: {
      if (!running && root.focusedWindowRefreshPending && root.visible) {
        focusedWindowRefreshDebounce.restart()
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

  Timer {
    id: focusedWindowRefreshDebounce
    interval: 80
    repeat: false
    onTriggered: {
      if (!root.visible || !root.compositorIntegration) {
        root.focusedWindowRefreshPending = false
        return
      }
      if (focusedWindowQuery.running) return
      root.focusedWindowRefreshPending = false
      focusedWindowQuery.running = true
    }
  }

  function requestWorkspaceRefresh() {
    if (!root.visible || !root.compositorIntegration) return
    root.workspaceRefreshPending = true
    workspaceRefreshDebounce.restart()
  }

  function requestFocusedWindowRefresh() {
    if (!root.visible || !root.compositorIntegration) return
    root.focusedWindowRefreshPending = true
    focusedWindowRefreshDebounce.restart()
  }

  function applyFocusedWindow(data) {
    if (!data || data.is_focused !== true) return false

    var title = typeof data.title === "string" ? data.title : ""
    root.focusedWindowTitle = title.replace(/\s+/g, " ").trim()
    root.focusedWindowAppId = typeof data.app_id === "string"
      ? data.app_id
      : (typeof data.appid === "string" ? data.appid : "")
    return true
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
              root.applyMangoMonitorSnapshot(event)
              root.workspaceRefreshPending = false
              root.focusedWindowRefreshPending = false
              workspaceRefreshDebounce.stop()
              focusedWindowRefreshDebounce.stop()
            } else {
              root.requestWorkspaceRefresh()
              root.requestFocusedWindowRefresh()
            }
            return
          }

          var workspaceEvent = event && event.WorkspacesChanged
          var windowEvent = event && event.WindowOpenedOrChanged
          var changedWindow = windowEvent && windowEvent.window
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
          var focusedWindowStateChanged = event && (
            event.WindowFocusChanged
            || event.WindowFocusTimestampChanged
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

          // Niri includes the complete window object in this event, including
          // title changes emitted by terminals such as Kitty. Apply it
          // directly so animated titles do not wait for a stale snapshot.
          if (root.applyFocusedWindow(changedWindow)) {
            root.focusedWindowRefreshPending = false
            focusedWindowRefreshDebounce.stop()
          } else if (workspaceStateChanged || focusedWindowStateChanged) {
            root.requestFocusedWindowRefresh()
          }
        } catch (e) {
          root.requestWorkspaceRefresh()
          root.requestFocusedWindowRefresh()
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

  onHorizontalChanged: {
    requestWorkspaceRefresh()
    requestFocusedWindowRefresh()
  }



  onVisibleChanged: {
    if (visible) {
      if (root.compositorIntegration) {
        requestWorkspaceRefresh()
        requestFocusedWindowRefresh()
      }
    }
  }

  Component.onCompleted: {
    if (root.visible) {
      if (root.compositorIntegration) {
        requestWorkspaceRefresh()
        requestFocusedWindowRefresh()
      }
    }
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

  function applyMangoMonitorSnapshot(data) {
    var monitor = null
    if (data && Array.isArray(data.monitors)) {
      for (var i = 0; i < data.monitors.length; i++) {
        if (data.monitors[i] && data.monitors[i].active === true) {
          monitor = data.monitors[i]
          break
        }
      }
      if (!monitor && data.monitors.length > 0) monitor = data.monitors[0]
    }

    var activeTag = null
    if (monitor && Array.isArray(monitor.tags)) {
      for (var tagIndex = 0; tagIndex < monitor.tags.length; tagIndex++) {
        if (monitor.tags[tagIndex] && monitor.tags[tagIndex].is_active === true) {
          activeTag = monitor.tags[tagIndex]
          break
        }
      }
    }
    root.mangoLayoutSymbol = activeTag && typeof activeTag.layout === "string"
      ? activeTag.layout.trim()
      : ""

    var client = monitor && monitor.active_client
    if (client && client.id !== undefined && client.id !== null) {
      var title = typeof client.title === "string" ? client.title : ""
      root.focusedWindowTitle = title.replace(/\s+/g, " ").trim()
      root.focusedWindowAppId = typeof client.appid === "string" ? client.appid : ""
    } else {
      root.focusedWindowTitle = ""
      root.focusedWindowAppId = ""
    }
  }

  function layoutNameForMangoToken(token) {
    var value = String(token || "").trim()
    if (!value) return ""

    var names = ({
      "T": "Tile",
      "TILE": "Tile",
      "S": "Scroller",
      "SCROLLER": "Scroller",
      "G": "Grid",
      "GRID": "Grid",
      "K": "Deck",
      "D": "Deck",
      "DECK": "Deck",
      "M": "Monocle",
      "MONOCLE": "Monocle",
      "CT": "Center Tile",
      "CENTER_TILE": "Center Tile",
      "RT": "Right Tile",
      "RIGHT_TILE": "Right Tile",
      "VT": "Vertical Tile",
      "VERTICAL_TILE": "Vertical Tile",
      "VS": "Vertical Scroller",
      "VERTICAL_SCROLLER": "Vertical Scroller",
      "VG": "Vertical Grid",
      "VERTICAL_GRID": "Vertical Grid",
      "VK": "Vertical Deck",
      "VERTICAL_DECK": "Vertical Deck",
      "TG": "TGMix",
      "TGMIX": "TGMix"
    })
    if (names[value.toUpperCase()]) return names[value.toUpperCase()]

    var words = value.replace(/[_-]+/g, " ").split(/\s+/)
    for (var i = 0; i < words.length; i++) {
      if (words[i].length > 0) {
        words[i] = words[i].charAt(0).toUpperCase() + words[i].slice(1).toLowerCase()
      }
    }
    return words.join(" ")
  }

  function parseWorkspaces(text) {
    var data = JSON.parse(text)
    return root.wmType === "mango"
      ? root.parseMangoMonitorList(data)
      : root.parseWorkspaceList(data)
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
    if (root.wmType === "mango")
      Quickshell.execDetached(["mmsg", "dispatch", "view," + idx])
    else
      Quickshell.execDetached(["sh", "-c", "niri msg action focus-workspace " + idx])
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

  Rectangle {
    id: workspaceGroup

    visible: root.integrated && root.visibleWorkspaces.length > 0
    anchors.centerIn: parent
    // Keep the same 34px track thickness as the horizontal control. In the
    // vertical layout the track is rotated by the layout itself, so its
    // length follows the workspace stack while the surface stays inset from
    // the 42px bar edge.
    width: root.horizontal
      ? parent.width
      : Math.min(34, Math.max(0, parent.width - Config.spacingSmall))
    height: root.horizontal
      ? Math.min(34, Math.max(0, parent.height - Config.spacingSmall))
      : Math.min(parent.height, Math.max(0, grid.implicitHeight + Config.spacingSmall * 2))
    radius: Math.min(Config.shapeLarge, width / 2, height / 2)
    color: root.workspaceGroupColor
    border.width: Config.themeBorderWidth
    border.color: Colors.outlineVariant
  }

  Grid {
    id: grid
    columns: root.horizontal ? Math.max(1, root.visibleWorkspaces.length) : 1
    anchors {
      left: parent.left
      right: root.horizontal ? undefined : parent.right
      top: root.horizontal ? undefined : parent.top
      verticalCenter: root.horizontal ? parent.verticalCenter : undefined
      leftMargin: root.horizontal ? 6 : 0
      topMargin: root.horizontal ? 0 : 6
    }
    height: root.horizontal
      ? Math.max(0, Math.min(28, parent.height - Config.spacingSmall * 2))
      : implicitHeight
    // The numbers style is one connected segmented control in either
    // orientation. Other marker styles keep their compact vertical spacing.
    spacing: root.workspaceStyle === "numbers"
      ? 0
      : (root.horizontal ? 0 : Config.spacingCompact)
    z: 1

    Repeater {
      model: root.visibleWorkspaces

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
        readonly property bool compactMarker: ["numbers", "magic", "kanji", "rings", "pacman"].indexOf(root.workspaceStyle) >= 0
        readonly property int markerMinimumSize: root.workspaceStyle === "magic" ? 22 : 26

        width: root.horizontal
          ? (root.workspaceStyle === "numbers"
            ? root.numberedWorkspaceWidth(modelData)
            : (compactMarker ? markerMinimumSize : (active ? 40 : (root.workspaceStyle === "dots" ? 16 : 12))))
          : grid.width
        height: root.horizontal
          ? grid.height
          : (root.workspaceStyle === "numbers"
            ? root.numberedWorkspaceHeight(modelData)
            : (compactMarker ? markerMinimumSize : (active ? 40 : (root.workspaceStyle === "dots" ? 16 : 12))))
        Behavior on width {
          enabled: !Config.reducedMotion
          SpringAnimation {
            spring: Config.motionSpatialSpring
            damping: Config.motionSpatialDamping
            mass: Config.motionSpatialMass
            epsilon: Config.motionSpatialEpsilon
          }
        }
        Behavior on height {
          enabled: !Config.reducedMotion
          SpringAnimation {
            spring: Config.motionSpatialSpring
            damping: Config.motionSpatialDamping
            mass: Config.motionSpatialMass
            epsilon: Config.motionSpatialEpsilon
          }
        }

        Rectangle {
          id: pillRect
          anchors.centerIn: parent
          visible: root.legacyWorkspaceShape && !(root.workspaceShape === "expressive"
            && Config.expressiveMotion
            && !root.horizontal
            && modelData.isFocused)
          width: root.workspaceShape === "pill" || root.workspaceShape === "expressive"
            ? (delegateItem.active
              ? (root.horizontal ? Math.min(32, delegateItem.width - 4) : 10)
              : (root.horizontal ? (modelData.isOccupied ? 10 : 6) : 4))
            : (delegateItem.active ? 28 : (modelData.isOccupied ? 10 : 6))
          height: root.workspaceShape === "pill" || root.workspaceShape === "expressive"
            ? (delegateItem.active
              ? (root.horizontal ? 10 : Math.min(32, delegateItem.height - 4))
              : (root.horizontal ? 4 : (modelData.isOccupied ? 10 : 6)))
            : (delegateItem.active ? 28 : (modelData.isOccupied ? 10 : 6))
          radius: Config.ghostTheme
            ? 0
            : (root.workspaceShape === "rounded"
              ? Math.min(Config.shapeMedium, width / 2, height / 2)
              : Math.min(width, height) / 2)

          color: {
            if (modelData.isFocused) return Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.styleAccent)
            var base = modelData.isOccupied
              ? (Config.nothingEvolution
                ? Qt.rgba(Colors.styleAccent.r, Colors.styleAccent.g, Colors.styleAccent.b, 0.72)
                : Colors.surfaceContainerHighest)
              : (Config.nothingEvolution
                ? Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.45)
                : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.2))
            return Qt.tint(base, wsMouse.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
          }
          border.width: root.integrated
            ? 0
            : (Config.nothingEvolution
              ? ((modelData.isFocused || wsMouse.containsMouse) ? Config.themeBorderWidth : 0)
              : (Config.nothingDesign
                ? 0
                : (Config.neoBrutalism
                  ? Config.themeBorderWidth
                  : (modelData.isFocused ? 0 : Config.themeBorderWidth))))
          border.color: {
            if (Config.neoBrutalism || Config.ghostTheme) return Colors.styleOutline
            if (Config.nothingEvolution) return Colors.styleOutline
            if (Config.nothingDesign) return "transparent"
            if (modelData.isFocused) return "transparent"
            return Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, modelData.isOccupied ? 0.3 : 0.1)
          }

          Behavior on width {
            enabled: !Config.reducedMotion
            SpringAnimation {
              spring: Config.motionSpatialSpring
              damping: Config.motionSpatialDamping
              mass: Config.motionSpatialMass
              epsilon: Config.motionSpatialEpsilon
            }
          }
          Behavior on height {
            enabled: !Config.reducedMotion
            SpringAnimation {
              spring: Config.motionSpatialSpring
              damping: Config.motionSpatialDamping
              mass: Config.motionSpatialMass
              epsilon: Config.motionSpatialEpsilon
            }
          }
          Behavior on color {
            ColorAnimation { duration: Config.animationDuration}
          }
        }

        ExpressiveShape {
          anchors.centerIn: parent
          width: pillRect.width + 4
          height: pillRect.height + 4
          visible: root.workspaceShape === "expressive"
            && Config.expressiveMotion
            && !root.horizontal
            && modelData.isFocused
          fillColor: Colors.primary
          shape: "blob"
          targetMorphProgress: modelData.isFocused ? 1.0 : 0.0
        }

        // Dots: the calm default marker used by compact workspace bars.
        Rectangle {
          visible: root.workspaceStyle === "dots"
          anchors.centerIn: parent
          width: modelData.isFocused ? 34 : 16
          height: 16
          radius: height / 2
          color: modelData.isFocused
            ? Qt.rgba(Colors.styleAccent.r, Colors.styleAccent.g, Colors.styleAccent.b, 0.20)
            : modelData.isOccupied
              ? Qt.rgba(Colors.styleAccent.r, Colors.styleAccent.g, Colors.styleAccent.b, 0.18)
              : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.06)
        }

        Rectangle {
          visible: root.workspaceStyle === "dots"
          anchors.centerIn: parent
          width: modelData.isFocused ? 26 : 8
          height: 8
          radius: height / 2
          color: modelData.isFocused || modelData.isOccupied
            ? Colors.styleAccent
            : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.34)
        }

        // Numbers: a connected navigation track in both orientations; the
        // active workspace becomes the raised pill shown in the bar.
        Rectangle {
          id: numberedWorkspaceShadow
          visible: root.workspaceStyle === "numbers"
            && modelData.isFocused
            && !Config.ghostTheme
          anchors.centerIn: parent
          anchors.verticalCenterOffset: root.horizontal
            ? (Config.neoBrutalism ? Config.themeShadowOffset : 2)
            : 0
          anchors.horizontalCenterOffset: !root.horizontal && Config.neoBrutalism
            ? Config.themeShadowOffset
            : 0
          width: root.horizontal ? root.numberedWorkspaceWidth(modelData) : root.numberedVerticalWidth
          height: root.horizontal ? grid.height : root.numberedWorkspaceHeight(modelData)
          radius: Config.ghostTheme ? 0 : Math.min(width, height) / 2
          color: Config.neoBrutalism
            ? Colors.styleShadow
            : Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 0.14)
          z: 0
        }

        Rectangle {
          id: numberedWorkspaceSurface
          visible: root.workspaceStyle === "numbers"
          anchors.centerIn: parent
          width: root.horizontal
            ? root.numberedWorkspaceWidth(modelData)
            : root.numberedVerticalWidth
          height: root.horizontal ? grid.height : root.numberedWorkspaceHeight(modelData)
          radius: Config.ghostTheme ? 0 : Math.min(width, height) / 2
          color: root.numberedWorkspaceFill(modelData)
          border.width: wsMouse.containsMouse && !modelData.isFocused ? Config.themeBorderWidth : 0
          border.color: Colors.styleOutline
          z: 1

          Row {
            visible: root.horizontal
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            spacing: modelData.isOccupied && !modelData.isFocused ? 4 : 0

            Text {
              text: String(modelData.idx)
              color: root.numberedWorkspaceTextColor(modelData)
              font.family: Config.monoFontFamily
              font.pixelSize: modelData.isFocused ? Config.typeLabelMediumSize : Config.typeLabelSmallSize
              font.weight: modelData.isFocused ? Config.typeStrongWeight : Config.typeRegularWeight
              font.letterSpacing: Config.typeMonoTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
            }

            Rectangle {
              visible: modelData.isOccupied && !modelData.isFocused
              width: 6
              height: 6
              radius: 3
              color: Colors.tertiary
              anchors.verticalCenter: parent.verticalCenter
              anchors.verticalCenterOffset: -1
            }
          }

          Text {
            id: verticalWorkspaceLabel
            visible: !root.horizontal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: modelData.isFocused
              ? 1
              : (modelData.isOccupied ? 4 : 0)
            text: String(modelData.idx)
            color: root.numberedWorkspaceTextColor(modelData)
            font.family: Config.monoFontFamily
            font.pixelSize: modelData.isFocused ? Config.typeLabelMediumSize : Config.typeLabelSmallSize
            font.weight: modelData.isFocused ? Config.typeStrongWeight : Config.typeRegularWeight
            font.letterSpacing: Config.typeMonoTracking
            lineHeight: Config.typeLabelMediumLineHeight
            lineHeightMode: Text.FixedHeight
          }

          Rectangle {
            visible: !root.horizontal && modelData.isOccupied && !modelData.isFocused
            width: 6
            height: 6
            radius: 3
            color: Colors.tertiary
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: verticalWorkspaceLabel.top
            anchors.bottomMargin: 1
          }
        }

        // Glyph: filled sparkle for focus, hollow sparkle for occupied, and a
        // small dot for empty workspaces.
        Text {
          visible: root.workspaceStyle === "magic"
          anchors.centerIn: parent
          text: modelData.isFocused ? String.fromCodePoint(0x2726)
            : (modelData.isOccupied ? String.fromCodePoint(0x2727) : String.fromCodePoint(0x00b7))
          color: root.workspaceMarkerColor(modelData)
          opacity: modelData.isFocused ? 1.0 : (modelData.isOccupied ? 0.72 : 0.36)
          font.family: Config.fontFamily
          font.pixelSize: modelData.isFocused ? 22 : 18
          renderType: Text.NativeRendering
        }

        // Kanji: the first ten workspaces use the compact Japanese numerals;
        // an out-of-range focused workspace remains readable in Arabic digits.
        Text {
          visible: root.workspaceStyle === "kanji"
          anchors.centerIn: parent
          text: modelData.idx >= 1 && modelData.idx <= 10
            ? ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"][modelData.idx - 1]
            : String(modelData.idx)
          color: root.workspaceMarkerColor(modelData)
          opacity: modelData.isFocused ? 1.0 : (modelData.isOccupied ? 0.72 : 0.36)
          font.family: "Noto Sans CJK JP"
          font.pixelSize: modelData.isFocused ? 15 : 13
          renderType: Text.NativeRendering
        }

        // Frame: a stable numeral row with an outline around the focused cell.
        Rectangle {
          visible: root.workspaceStyle === "rings"
          anchors.centerIn: parent
          width: 22
          height: 22
          radius: Config.shapeCompact
          color: "transparent"
          border.width: modelData.isFocused || wsMouse.containsMouse ? Config.themeBorderWidth : 0
          border.color: Colors.styleAccent

          Text {
            anchors.centerIn: parent
            text: String(modelData.idx)
            color: root.workspaceMarkerColor(modelData)
            opacity: modelData.isFocused || wsMouse.containsMouse ? 1.0 : (modelData.isOccupied ? 0.68 : 0.30)
            font.family: Config.monoFontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeMonoTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
          }
        }

        // Aurora: one flat streak, with inactive workspaces reduced to dots.
        Item {
          visible: root.workspaceStyle === "aurora"
          anchors.centerIn: parent
          width: root.horizontal ? (modelData.isFocused ? 32 : 10) : 16
          height: root.horizontal ? 16 : (modelData.isFocused ? 32 : 10)

          Rectangle {
            anchors.centerIn: parent
            width: root.horizontal ? (modelData.isFocused ? 28 : (modelData.isOccupied ? 6 : 4)) : (modelData.isFocused ? 3 : (modelData.isOccupied ? 6 : 4))
            height: root.horizontal ? (modelData.isFocused ? 3 : (modelData.isOccupied ? 6 : 4)) : (modelData.isFocused ? 28 : (modelData.isOccupied ? 6 : 4))
            radius: Math.min(width, height) / 2
            color: root.workspaceMarkerColor(modelData)
            opacity: modelData.isFocused ? 0.92 : (modelData.isOccupied ? 0.62 : 0.18)
          }
        }

        // Pacman: a focused mouth, occupied pellets, and dim empty dots.
        PacmanMarker {
          visible: root.workspaceStyle === "pacman"
          anchors.centerIn: parent
          focused: modelData.isFocused
          occupied: modelData.isOccupied
          hovered: wsMouse.containsMouse
          markerColor: root.workspaceMarkerColor(modelData)
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
