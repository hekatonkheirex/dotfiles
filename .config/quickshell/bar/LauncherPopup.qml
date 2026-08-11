import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "primitives"
import "../config"

PanelWindow {
  id: root

  property int anchorY: 0

  signal dismissed()

  implicitWidth: wallpaperMode
    ? Math.min(Config.commandCenterMaxWidth, Math.max(Config.popupWidth, Screen.desktopAvailableWidth - 32))
    : Config.popupWidth
  visible: false
  implicitHeight: wallpaperMode
    ? Math.min(Config.commandCenterMaxHeight, wallpaperGridHeight + 86)
    : Math.min(clipItem.implicitHeight + 32, 500)

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Config.motionMedium
      easing.type: Easing.OutCubic
    }
  }
  Behavior on implicitHeight {
    NumberAnimation {
      duration: Config.motionMedium
      easing.type: Easing.OutCubic
    }
  }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true

  anchors.left: true
  margins.left: Config.barWidth + 4
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(10, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  ListModel { id: appModel }
  ListModel {
    id: filteredModel

    // Keep one stable role schema while switching between apps, actions, and
    // wallpapers. Without this, roles introduced by a later append can be
    // unavailable to existing delegates and resolve as undefined.
    ListElement {
      kind: "app"
      actionId: ""
      name: ""
      comment: ""
      keywords: ""
      generic_name: ""
      categories: ""
      icon: ""
      path: ""
      exec: ""
      terminal: false
    }
  }
  ListModel {
    id: actionModel

    ListElement {
      kind: "action"
      actionId: "quickmenu"
      name: "Power Options"
      comment: "Log out, restart, sleep, or shut down"
      keywords: "quick menu power options logout restart sleep shutdown"
      icon: "power_settings_new"
    }
    ListElement {
      kind: "action"
      actionId: "commandcenter"
      name: "Settings"
      comment: "Appearance, account, and general preferences"
      keywords: "settings preferences appearance account general dashboard"
      icon: "settings"
    }
    ListElement {
      kind: "action"
      actionId: "lock"
      name: "Lock session"
      comment: "Lock the desktop"
      keywords: "lock screen security"
      icon: "lock"
    }
    ListElement {
      kind: "action"
      actionId: "theme-auto"
      name: "Automatic theme"
      comment: "Follow the wallpaper brightness"
      keywords: "theme mode light dark system"
      icon: "brightness_auto"
    }
    ListElement {
      kind: "action"
      actionId: "theme-light"
      name: "Light theme"
      comment: "Use the light desktop theme"
      keywords: "theme mode light"
      icon: "light_mode"
    }
    ListElement {
      kind: "action"
      actionId: "theme-dark"
      name: "Dark theme"
      comment: "Use the dark desktop theme"
      keywords: "theme mode dark"
      icon: "dark_mode"
    }
  }
  ListModel { id: wallpaperModel }

  property string searchText: ""
  property int selectedIndex: 0
  property bool voiceRecording: false
  property bool voiceTranscribing: false
  readonly property bool actionMode: searchText.trim().startsWith(">")
  readonly property bool wallpaperMode: searchText.trim().startsWith("@")
  readonly property int wallpaperCellWidth: 180
  readonly property int wallpaperCellHeight: 124
  readonly property int wallpaperCardWidth: 164
  readonly property int wallpaperCardHeight: 108
  readonly property int wallpaperImageInset: 1
  readonly property int wallpaperCellGap: wallpaperCellWidth - wallpaperCardWidth
  // The grid has two 12 px margins: one from clipItem and one from the frame.
  readonly property int wallpaperGridAvailableWidth: Math.max(1, implicitWidth - 48)
  readonly property int wallpaperColumns: Math.max(1,
    Math.floor((wallpaperGridAvailableWidth + wallpaperCellGap) / wallpaperCellWidth))
  // Center the visible cards, rather than the larger cells that contain them.
  readonly property int wallpaperRowWidth:
    wallpaperColumns * wallpaperCellWidth - wallpaperCellGap
  readonly property int wallpaperRows: wallpaperMode
    ? Math.max(1, Math.ceil(Math.max(1, filteredModel.count) / wallpaperColumns))
    : 1
  readonly property int wallpaperGridHeight:
    Math.min(480, Math.max(220, wallpaperRows * wallpaperCellHeight + 16))

  Process {
    id: wallpaperProc
    command: [
      "find", Quickshell.env("HOME") + "/Pictures/Walls", "-maxdepth", "1", "-type", "f",
      "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")",
      "-printf", "%f\\n"
    ]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        wallpaperModel.clear()
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var filename = lines[i].trim()
          if (!filename) continue
          wallpaperModel.append({
            kind: "wallpaper",
            name: filename,
            path: filename,
            comment: "Apply wallpaper",
            keywords: filename.replace(/[._-]+/g, " "),
            icon: "wallpaper"
          })
        }
        if (root.visible) root.filterApps()
      }
    }
  }

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

  Process {
    id: recorderProc
    command: ["pw-record", "--rate", "16000", "--channels", "1", "--format", "s16", "/tmp/qs-voice.wav"]
    running: false
  }

  Process {
    id: transcriberProc
    command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/voice-search.py", "/tmp/qs-voice.wav"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.voiceTranscribing = false
        var t = text.trim()
        if (t.length > 0) {
          searchInputControl.text = t
          root.searchText = t
          root.selectedIndex = 0
          filterApps()
        }
      }
    }
  }

  Component.onCompleted: {
    filteredModel.clear()
    desktopProc.running = true
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible && Config.isNiri) root.dismissed()
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

  function runLauncherScript(name) {
    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/" + name])
  }

  function setThemeMode(mode, preference) {
    Colors.themePreference = preference
    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/sync-theme-mode.sh", mode])
  }

  function appendFilteredResult(item, fallbackKind) {
    filteredModel.append({
      kind: item.kind || fallbackKind,
      actionId: item.actionId || "",
      name: item.name || "",
      comment: item.comment || "",
      keywords: item.keywords || "",
      generic_name: item.generic_name || "",
      categories: item.categories || "",
      icon: item.icon || "",
      path: item.path || "",
      exec: item.exec || "",
      terminal: item.terminal === true
    })
  }

  function runAction(actionId) {
    switch (actionId) {
      case "quickmenu":
        runLauncherScript("quickmenu")
        break
      case "commandcenter":
        runLauncherScript("commandcenter")
        break
      case "lock":
        runLauncherScript("lock")
        break
      case "theme-auto":
        setThemeMode("auto", 0)
        break
      case "theme-light":
        setThemeMode("light", 1)
        break
      case "theme-dark":
        setThemeMode("dark", 2)
        break
      default:
        return
    }
    dismissed()
  }

  function applyWallpaper(filename) {
    if (!filename) return
    Quickshell.execDetached([
      "bash",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh",
      filename
    ])
    dismissed()
  }

  function scoreSpecialResult(item, query) {
    var name = (item.name || "").toLowerCase()
    var comment = (item.comment || "").toLowerCase()
    var keywords = (item.keywords || "").toLowerCase()
    var score = 0

    if (!query) return 1
    if (name === query) score += 500
    else if (name.indexOf(query) === 0) score += 300
    else if (name.indexOf(query) !== -1) score += 150
    if (comment.indexOf(query) !== -1) score += 80
    if (keywords.indexOf(query) !== -1) score += 60

    var terms = query.split(/\s+/)
    for (var i = 0; i < terms.length; i++) {
      var term = terms[i]
      if (!term) continue
      if (name.indexOf(term) !== -1) score += 25
      else if (comment.indexOf(term) !== -1 || keywords.indexOf(term) !== -1) score += 10
      else return 0
    }
    return score
  }

  function filterSpecialResults(model, query) {
    var matches = []
    for (var i = 0; i < model.count; i++) {
      var item = model.get(i)
      var score = scoreSpecialResult(item, query)
      if (score > 0) matches.push({ item: item, score: score })
    }

    matches.sort(function(a, b) {
      if (b.score !== a.score) return b.score - a.score
      return a.item.name.localeCompare(b.item.name)
    })

    for (var j = 0; j < matches.length; j++) {
      appendFilteredResult(matches[j].item, "action")
    }
    selectedIndex = Math.max(0, Math.min(selectedIndex, filteredModel.count - 1))
  }

  function filterApps() {
    filteredModel.clear()
    var q = searchText.toLowerCase().trim()
    if (q.startsWith(">")) {
      filterSpecialResults(actionModel, q.substring(1).trim())
      return
    }
    if (q.startsWith("@")) {
      filterSpecialResults(wallpaperModel, q.substring(1).trim())
      return
    }
    if (q === "") {
      for (var i = 0; i < appModel.count; i++) {
        appendFilteredResult(appModel.get(i), "app")
      }
      selectedIndex = 0
      return
    }

    var matches = []
    for (var i = 0; i < appModel.count; i++) {
      var app = appModel.get(i)
      var score = 0
      var nameLower = app.name.toLowerCase()
      var commentLower = (app.comment || "").toLowerCase()
      var genNameLower = (app.generic_name || "").toLowerCase()
      var keywordsLower = (app.keywords || "").toLowerCase()
      var categoriesLower = (app.categories || "").toLowerCase()

      // 1. Check exact or prefix match on Name (highest priority)
      if (nameLower === q) {
        score += 500
      } else if (nameLower.indexOf(q) === 0) {
        score += 300
      } else if (nameLower.indexOf(q) !== -1) {
        score += 150
      }

      // 2. Check Generic Name (e.g. "Web Browser", "Text Editor")
      if (genNameLower === q) {
        score += 250
      } else if (genNameLower.indexOf(q) === 0) {
        score += 180
      } else if (genNameLower.indexOf(q) !== -1) {
        score += 100
      }

      // 3. Check keywords (e.g. "browser", "internet")
      if (keywordsLower.indexOf(q) !== -1) {
        score += 80
      }

      // 4. Check Categories
      if (categoriesLower.indexOf(q) !== -1) {
        score += 60
      }

      // 5. Check description/comment
      if (commentLower.indexOf(q) !== -1) {
        score += 40
      }

      // 6. Check individual terms for multi-word queries
      var terms = q.split(/\s+/)
      if (terms.length > 1) {
        var allTermsMatch = true
        var termScore = 0
        for (var t = 0; t < terms.length; t++) {
          var term = terms[t]
          if (!term) continue
          var foundTerm = false
          if (nameLower.indexOf(term) !== -1) {
            termScore += 30
            foundTerm = true
          }
          if (genNameLower.indexOf(term) !== -1) {
            termScore += 20
            foundTerm = true
          }
          if (keywordsLower.indexOf(term) !== -1) {
            termScore += 15
            foundTerm = true
          }
          if (commentLower.indexOf(term) !== -1) {
            termScore += 10
            foundTerm = true
          }
          if (!foundTerm) {
            allTermsMatch = false
          }
        }
        if (allTermsMatch) {
          score += termScore + 50
        } else {
          score += termScore * 0.5
        }
      }

      if (score > 0) {
        matches.push({ app: app, score: score })
      }
    }

    // Sort by score descending, secondary sort alphabetically by name
    matches.sort(function(a, b) {
      if (b.score !== a.score) {
        return b.score - a.score
      }
      return a.app.name.localeCompare(b.app.name)
    })

    for (var j = 0; j < matches.length; j++) {
      appendFilteredResult(matches[j].app, "app")
    }

    selectedIndex = Math.max(0, Math.min(selectedIndex, filteredModel.count - 1))
  }

  Timer {
    id: focusTimer
    interval: 1
    running: visible
    onTriggered: searchInputControl.input.forceActiveFocus()
  }

  Timer {
    id: focusCheck
    interval: 300
    running: visible
    repeat: true
    onTriggered: {
      if (!searchInputControl.input.activeFocus) {
        stop()
        dismissed()
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      searchInputControl.text = ""
      searchText = ""
      selectedIndex = 0
      filteredModel.clear()
      if (appModel.count > 0) {
        for (var i = 0; i < appModel.count; i++) {
          appendFilteredResult(appModel.get(i), "app")
        }
      }
      wallpaperProc.running = false
      wallpaperProc.running = true
      entryAnimation.start()
      root.voiceRecording = false
      root.voiceTranscribing = false
    } else {
      if (root.voiceRecording) {
        root.voiceRecording = false
        recorderProc.running = false
      }
      if (root.voiceTranscribing) {
        root.voiceTranscribing = false
        transcriberProc.running = false
      }
    }
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    color: Colors.surfaceContainer
    radius: 24
    border.color: Colors.outlineVariant
    border.width: 1

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
        duration: Config.motionLong
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: transX
        property: "x"
        from: -30
        to: 0
        duration: Config.motionLong
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: bg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: Config.motionMedium
        easing.type: Easing.OutCubic
      }
    }

    ColumnLayout {
      id: clipItem
      anchors { fill: parent; margins: 12 }
      spacing: 12

      TextFieldControl {
        id: searchInputControl
        Layout.fillWidth: true
        height: 46
        leadingIcon: "search"
        leadingIconSize: 22
        placeholder: root.voiceRecording
          ? "Listening... Click mic to stop."
          : (root.voiceTranscribing
            ? "Transcribing..."
            : (root.actionMode
              ? "Run a shell action..."
              : (root.wallpaperMode ? "Search wallpapers..." : "Search apps · > actions · @ walls")))
        showPlaceholderOnFocus: true
        captureHorizontalArrows: root.wallpaperMode
        accessibleName: "Search applications"

        onAccepted: {
          if (filteredModel.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < filteredModel.count) {
            var result = filteredModel.get(root.selectedIndex)
            if (result.kind === "action") root.runAction(result.actionId)
            else if (result.kind === "wallpaper") root.applyWallpaper(result.path)
            else root.launchApp(result.exec, result.terminal)
          }
        }
        onEscapePressed: root.dismissed()
        onUpPressed: {
          if (root.wallpaperMode) root.moveWallpaperSelection(Qt.Key_Up)
          else root.moveSelection(-1)
        }
        onDownPressed: {
          if (root.wallpaperMode) root.moveWallpaperSelection(Qt.Key_Down)
          else root.moveSelection(1)
        }
        onLeftPressed: root.moveWallpaperSelection(Qt.Key_Left)
        onRightPressed: root.moveWallpaperSelection(Qt.Key_Right)

        Text {
          id: micIcon
          text: root.voiceRecording ? "stop" : (root.voiceTranscribing ? "sync" : "mic")
          color: root.voiceRecording ? Colors.destructive : (root.voiceTranscribing ? Colors.info : Colors.fgSurfaceVariant)
          font.family: Config.iconFont
          font.pixelSize: 22

          onRotationChanged: {
            if (!root.voiceTranscribing && rotation !== 0) rotation = 0
          }

          RotationAnimator {
            target: micIcon
            running: root.voiceTranscribing && !Config.reducedMotion
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1200
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (!root.voiceRecording && !root.voiceTranscribing) {
                root.voiceRecording = true
                Quickshell.execDetached(["rm", "-f", "/tmp/qs-voice.wav"])
                recorderProc.running = true
              } else if (root.voiceRecording) {
                root.voiceRecording = false
                root.voiceTranscribing = true
                recorderProc.running = false
                transcriberProc.running = true
              }
            }
          }
        }
      }

      Connections {
        target: searchInputControl.input
        function onTextChanged() {
          root.searchText = searchInputControl.text
          root.selectedIndex = 0
          root.filterApps()
        }
      }

      ListView {
        id: appList
        Layout.fillWidth: true
        Layout.preferredHeight: root.wallpaperMode ? 0 : Math.min(contentHeight, 380)
        visible: !root.wallpaperMode
        model: filteredModel
        clip: true
        currentIndex: root.selectedIndex
        spacing: 4

        delegate: ListItem {
          width: appList.width
          height: 44
          radius: 22
          leadingIcon: model.kind === "action" || model.kind === "wallpaper" ? model.icon : ""
          leadingImageSource: model.kind !== "action" && model.kind !== "wallpaper" && model.icon !== ""
            ? "file://" + model.icon : ""
          leadingFallbackText: model.kind !== "action" && model.kind !== "wallpaper" && model.icon === ""
            ? model.name.charAt(0).toUpperCase() : ""
          title: model.name
          subtitle: model.comment || ""
          selected: root.selectedIndex === index
          accessibleName: model.name
          accessibleDescription: model.comment || (model.kind === "action" ? "Shell action" : "Application")
          onHoveredChanged: {
            if (hovered) root.selectedIndex = index
          }
          onClicked: {
            root.selectedIndex = index
            if (model.kind === "action") root.runAction(model.actionId)
            else if (model.kind === "wallpaper") root.applyWallpaper(model.path)
            else root.launchApp(model.exec, model.terminal)
          }
        }
      }

      Rectangle {
        id: wallpaperFrame
        Layout.fillWidth: true
        Layout.preferredHeight: root.wallpaperMode ? root.wallpaperGridHeight : 0
        visible: root.wallpaperMode
        radius: Config.shapeMedium
        color: Colors.surfaceContainerLow
        border.color: Colors.outlineVariant
        border.width: 1
        clip: true

        GridView {
          id: wallpaperGrid
          anchors.fill: parent
          anchors.margins: 12
          leftMargin: Math.max(0, (width - root.wallpaperRowWidth) / 2)
          cellWidth: root.wallpaperCellWidth
          cellHeight: root.wallpaperCellHeight
          model: filteredModel
          currentIndex: root.selectedIndex
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          activeFocusOnTab: true

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
                || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
              root.moveWallpaperSelection(event.key)
              event.accepted = true
              return
            }
            if ((event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                && root.selectedIndex >= 0 && root.selectedIndex < filteredModel.count) {
              root.applyWallpaper(filteredModel.get(root.selectedIndex).path)
              event.accepted = true
            }
          }

          delegate: Rectangle {
            id: wallpaperDelegate
            width: root.wallpaperCardWidth
            height: root.wallpaperCardHeight
            radius: Config.shapeMedium
            color: Colors.surfaceContainerHigh
            clip: true

            readonly property bool isSelected: GridView.isCurrentItem
            readonly property bool isFocused: isSelected && wallpaperGrid.activeFocus
            readonly property string thumbnailSource:
              "file://" + Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs/" + model.path
            readonly property string originalSource:
              "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + model.path

            Accessible.role: Accessible.Button
            Accessible.name: model.name
            Accessible.description: "Apply wallpaper"

            Image {
              id: wallpaperThumb
              anchors.fill: parent
              anchors.margins: root.wallpaperImageInset
              source: model.path ? wallpaperDelegate.thumbnailSource : ""
              sourceSize.width: 200
              sourceSize.height: 130
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              smooth: true
              visible: false

              onStatusChanged: {
                if (model.path && status === Image.Error && source !== wallpaperDelegate.originalSource) {
                  source = wallpaperDelegate.originalSource
                }
              }
            }

            // Rectangle.clip is rectangular even when the Rectangle has a
            // radius. Use the same Qt Quick mask pattern as the profile images
            // so light wallpaper pixels cannot show through square corners.
            Rectangle {
              id: wallpaperMask
              anchors.fill: parent
              anchors.margins: root.wallpaperImageInset
              radius: Math.max(0, wallpaperDelegate.radius - root.wallpaperImageInset)
              color: "black"
              visible: false
              layer.enabled: true
            }

            MultiEffect {
              id: wallpaperThumbEffect
              anchors.fill: parent
              anchors.margins: root.wallpaperImageInset
              source: wallpaperThumb
              maskEnabled: true
              maskSource: wallpaperMask
            }

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: {
                if (wallpaperMouse.pressed) {
                  return Qt.tint("transparent", Colors.pressOverlay)
                }
                if (wallpaperDelegate.isFocused) {
                  return Qt.tint("transparent", Colors.focusOverlay)
                }
                if (wallpaperMouse.containsMouse) {
                  return Qt.tint("transparent", Colors.hoverOverlay)
                }
                if (wallpaperDelegate.isSelected) {
                  return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                }
                return "transparent"
              }
              border.width: wallpaperDelegate.isSelected || wallpaperMouse.containsMouse ? 2 : 1
              border.color: wallpaperDelegate.isSelected || wallpaperMouse.containsMouse
                ? Colors.primary : Colors.outlineVariant

              Behavior on color {
                ColorAnimation { duration: Config.animationDuration }
              }
              Behavior on border.width {
                NumberAnimation { duration: Config.animationDuration }
              }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 26
              color: Qt.rgba(Colors.surfaceContainerLowest.r, Colors.surfaceContainerLowest.g,
                Colors.surfaceContainerLowest.b, 0.78)

              Text {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: Text.AlignVCenter
                text: model.name
                color: Colors.fgSurface
                font.family: Config.fontFamily
                font.pixelSize: Config.fontPixelSize
                elide: Text.ElideRight
              }
            }

            MouseArea {
              id: wallpaperMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                wallpaperGrid.currentIndex = index
                wallpaperGrid.forceActiveFocus()
                root.applyWallpaper(model.path)
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: filteredModel.count === 0
            text: "No wallpapers found"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 2
          }
        }
      }

      Item {
        Layout.fillHeight: !root.wallpaperMode
        visible: !root.wallpaperMode
      }
    }
  }

  function moveSelection(delta) {
    if (filteredModel.count === 0) return
    selectedIndex = Math.max(0, Math.min(filteredModel.count - 1, selectedIndex + delta))
    ensureVisible(selectedIndex)
  }

  function moveWallpaperSelection(key) {
    if (!root.wallpaperMode || filteredModel.count === 0) return

    var columns = Math.max(1, wallpaperColumns)
    var current = Math.max(0, Math.min(filteredModel.count - 1, selectedIndex))
    var row = Math.floor(current / columns)
    var column = current % columns
    var next = current

    if (key === Qt.Key_Left && column > 0) {
      next = current - 1
    } else if (key === Qt.Key_Right && column < columns - 1 && current + 1 < filteredModel.count) {
      next = current + 1
    } else if (key === Qt.Key_Up && row > 0) {
      var previousRowStart = (row - 1) * columns
      next = Math.min(previousRowStart + column, Math.min(filteredModel.count - 1, previousRowStart + columns - 1))
    } else if (key === Qt.Key_Down) {
      var nextRowStart = (row + 1) * columns
      if (nextRowStart < filteredModel.count) {
        next = Math.min(nextRowStart + column, filteredModel.count - 1)
      }
    }

    selectedIndex = next
    ensureVisible(next)
  }

  function ensureVisible(idx) {
    if (root.wallpaperMode) wallpaperGrid.positionViewAtIndex(idx, GridView.Contain)
    else appList.positionViewAtIndex(idx, ListView.Contain)
  }
}
