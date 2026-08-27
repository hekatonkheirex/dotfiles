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
  property string focusedWindowTitle: ""
  property string focusedWindowAppId: ""
  readonly property string focusedWindowInfo: focusedWindowTitle !== "" ? focusedWindowTitle : focusedWindowAppId
  readonly property string focusedWindowProgram: formatProgramName(focusedWindowAppId)

  readonly property string wmType: Config.wmType
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
    columns: root.horizontal ? Math.max(1, root.visibleWorkspaces.length) : 1
    anchors {
      left: parent.left
      right: root.horizontal ? undefined : parent.right
      top: parent.top
      bottom: root.horizontal ? parent.bottom : undefined
      leftMargin: root.horizontal ? 6 : 0
      topMargin: root.horizontal ? 0 : 6
    }
    spacing: Config.spacingCompact

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
          ? (compactMarker ? markerMinimumSize : (active ? 40 : (root.workspaceStyle === "dots" ? 16 : 12)))
          : grid.width
        height: root.horizontal
          ? grid.height
          : (compactMarker ? markerMinimumSize : (active ? 40 : (root.workspaceStyle === "dots" ? 16 : 12)))
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

        // Numbers: stable circular-ish cells keep the workspace identity
        // visible instead of relying only on relative position.
        Rectangle {
          visible: root.workspaceStyle === "numbers"
          anchors.centerIn: parent
          width: 22
          height: 22
          radius: Config.shapeCompact
          color: root.workspaceMarkerFill(modelData)
          border.width: modelData.isFocused || wsMouse.containsMouse ? Config.themeBorderWidth : 0
          border.color: Colors.styleAccent

          Text {
            anchors.centerIn: parent
            text: String(modelData.idx)
            color: root.workspaceMarkerTextColor(modelData)
            font.family: Config.monoFontFamily
            font.pixelSize: modelData.isFocused ? Config.typeLabelMediumSize : Config.typeLabelSmallSize
            font.weight: modelData.isFocused ? Config.typeStrongWeight : Config.typeRegularWeight
            font.letterSpacing: Config.typeMonoTracking
            lineHeight: Config.typeLabelMediumLineHeight
            lineHeightMode: Text.FixedHeight
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
