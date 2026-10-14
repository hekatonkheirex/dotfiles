import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "primitives"
import "../config"
import "../config/LauncherLayout.js" as LauncherLayout

PanelWindow {
  id: root

  property int anchorY: 0

  signal dismissed()
  // "@" hands off to the full-width wallpaper filmstrip; the text typed after
  // it travels along as the initial jump query.
  signal wallpapersRequested(string query)

  // Her rofi geometry (R6c): half the screen, centered by shell.qml, eight
  // fixed lines. The row is 10 S padding around one text line.
  readonly property int textPx: Math.round(14 * Config.elenaScale)
  readonly property int rowHeight: Math.round(textPx * 1.5) + 2 * Config.dp(10)
  implicitWidth: LauncherLayout.windowWidth(Screen.width, Config.dp(LauncherLayout.MIN_WIDTH_DP), Config.spacingPage)
  visible: false
  implicitHeight: Math.min(screenH - Config.spacingPage, clipItem.implicitHeight + 2 * Config.dp(6))

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
  WlrLayershell.namespace: Config.layerNamespace("popup")
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property int screenH: Screen.desktopAvailableHeight

  readonly property var selectedResult: filteredModel.count > 0
    && selectedIndex >= 0 && selectedIndex < filteredModel.count ? filteredModel.get(selectedIndex) : null
  readonly property string selectionActionLabel: selectedResult && selectedResult.kind === "clipboard"
    ? "Restore clipboard entry" : (selectedResult && selectedResult.kind === "clipboard-action"
      ? selectedResult.name : (selectedResult && selectedResult.kind === "action" ? "Run action" : "Open application"))

  function activateSelection() {
    if (!root.selectedResult) return
    var result = root.selectedResult
    if (result.kind === "action" || result.kind === "clipboard-action") root.runAction(result.actionId)
    else if (result.kind === "clipboard") root.restoreClipboardEntry(result.clipboardLine)
    else root.launchApp(result.argv, result.terminal)
  }

  function launchCommandText(argv) {
    // Copy runnable arguments, not the desktop file's %U/%F template.
    return root.normalizeArgv(argv).map(function(arg) {
      return "'" + arg.replace(/'/g, "'\\''") + "'"
    }).join(" ")
  }

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
      // ListModel roles are type-stable. QML converts arrays retrieved through
      // ListModel.get() to QObject values, so keep the transport form as JSON
      // text and decode it only at the process-launch boundary.
      argv: ""
      clipboardLine: ""
      clipboardPreview: ""
      clipboardMime: ""
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
      actionId: "settings"
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
    ListElement {
      kind: "action"
      actionId: "clipboard-open"
      name: "Clipboard history"
      comment: "Search and restore copied entries"
      keywords: "clipboard copy paste history provider"
      icon: "content_paste"
    }
    ListElement {
      kind: "action"
      actionId: "capture-screen"
      name: "Capture screen"
      comment: "Save a screenshot and copy it to the clipboard"
      keywords: "screenshot capture screen clipboard image"
      icon: "screenshot_monitor"
    }
    ListElement {
      kind: "action"
      actionId: "capture-region"
      name: "Capture region"
      comment: "Select a region, save it, and copy it to the clipboard"
      keywords: "screenshot capture region select clipboard image"
      icon: "crop"
    }
  }
  ListModel { id: clipboardModel }

  property string searchText: ""
  // Set by the sidebar search field (shell.qml) before the launcher opens; applied
  // once after the on-show reset below, then cleared.
  property string initialQuery: ""
  property int selectedIndex: 0
  property bool clipboardLoaded: false
  property bool clipboardLoading: false
  property bool clipboardWipeArmed: false
  property bool clipboardWipeRunning: false
  property string clipboardStatus: ""
  readonly property bool actionMode: searchText.trim().startsWith(">")
  readonly property bool wallpaperMode: searchText.trim().startsWith("@")
  readonly property bool clipboardMode: searchText.trim().startsWith(";")

  onWallpaperModeChanged: {
    if (!root.wallpaperMode) return
    root.wallpapersRequested(root.searchText.trim().substring(1).trim())
    root.dismissed()
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
              // Arrays become nested QQmlListModel objects when stored in a
              // ListModel. Serialize before insertion so ListModel.get()
              // returns a stable string that can be decoded at launch time.
              json[i].argv = root.serializeArgv(json[i].argv)
              appModel.append(json[i])
            }
            if (visible) filterApps()
          } catch (e) { print("LauncherPopup parse error:", e) }
        }
      }
    }
  }

  Process {
    id: clipboardProc
    command: ["sh", "-c", "if command -v cliphist >/dev/null 2>&1; then cliphist list; fi"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        clipboardModel.clear()
        var lines = (text || "").split(/\r?\n/)
        for (var i = 0; i < lines.length; i++) {
          var rawLine = lines[i].replace(/\r$/, "")
          if (rawLine === "") continue

          var separator = rawLine.indexOf("\t")
          var preview = separator >= 0 ? rawLine.substring(separator + 1) : rawLine
          clipboardModel.append({
            kind: "clipboard",
            actionId: "",
            name: root.clipboardDisplayText(preview),
            comment: "Press Enter to restore this entry",
            keywords: "clipboard copy paste " + preview,
            generic_name: "",
            categories: "",
            icon: root.clipboardMime(preview) === "image" ? "image" : "content_paste",
            path: "",
            exec: "",
            terminal: false,
            clipboardLine: rawLine,
            clipboardPreview: root.clipboardDisplayText(preview),
            clipboardMime: root.clipboardMime(preview)
          })
        }
        root.clipboardLoaded = true
        root.clipboardLoading = false
        if (root.visible && root.clipboardMode) root.filterApps()
      }
    }

    onRunningChanged: {
      if (running) root.clipboardLoading = true
    }
  }

  Process {
    id: clipboardWipeProc
    command: ["sh", "-c", "if command -v cliphist >/dev/null 2>&1; then exec cliphist wipe; else exit 127; fi"]
    running: false

    onExited: (exitCode) => {
      root.clipboardWipeRunning = false
      if (exitCode === 0) {
        clipboardModel.clear()
        root.clipboardLoaded = false
        root.clipboardLoading = false
        root.clipboardStatus = "Clipboard history cleared"
        root.filterApps()
        clipboardRefreshTimer.restart()
      } else {
        root.clipboardStatus = "Could not clear clipboard history"
        root.filterApps()
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

  function launchApp(argv, terminal) {
    var args = root.normalizeArgv(argv)
    if (args.length === 0) {
      root.dismissed()
      return
    }
    var command = terminal ? ["kitty", "-e"].concat(args) : args
    Quickshell.execDetached(command)
    dismissed()
  }

  function normalizeArgv(value) {
    var args = value
    if (typeof args === "string") {
      try {
        args = JSON.parse(args)
      } catch (e) {
        return []
      }
    }
    if (!Array.isArray(args)) return []

    var normalized = []
    for (var i = 0; i < args.length; i++) {
      if (typeof args[i] === "string") normalized.push(args[i])
    }
    return normalized
  }

  function serializeArgv(value) {
    return JSON.stringify(root.normalizeArgv(value))
  }

  function runLauncherScript(name) {
    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/" + name])
  }

  function setThemeMode(preference) {
    Settings.themePreference = preference
    Settings.save()
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
      terminal: item.terminal === true,
      argv: root.serializeArgv(item.argv),
      clipboardLine: item.clipboardLine || "",
      clipboardPreview: item.clipboardPreview || "",
      clipboardMime: item.clipboardMime || ""
    })
  }

  function clipboardDisplayText(value) {
    var clean = String(value || "").replace(/\s+/g, " ").trim()
    if (clean === "") return "(empty clipboard entry)"
    return clean.length > 120 ? clean.substring(0, 117) + "…" : clean
  }

  function clipboardMime(value) {
    var clean = String(value || "").toLowerCase()
    return clean.indexOf("image/") === 0 || clean.indexOf("[image") === 0 ? "image" : "text"
  }

  function refreshClipboard() {
    if (!root.clipboardMode || clipboardProc.running) return
    root.clipboardLoaded = false
    root.clipboardLoading = true
    clipboardModel.clear()
    clipboardProc.running = true
  }

  function requestClipboardWipe() {
    if (root.clipboardWipeRunning) return

    if (root.clipboardWipeArmed) {
      root.clipboardWipeArmed = false
      root.clipboardStatus = "Clearing clipboard history…"
      root.clipboardWipeRunning = true
      clipboardWipeProc.running = true
      root.filterApps()
      return
    }

    root.clipboardStatus = ""
    root.clipboardWipeArmed = true
    clipboardWipeTimer.restart()
    root.filterApps()
  }

  function deleteClipboardEntry(line) {
    if (!line) return
    Quickshell.execDetached(["sh", "-c",
      "if command -v cliphist >/dev/null 2>&1; then printf '%s\\n' \"$1\" | cliphist delete; fi",
      "clipboard-delete", line])
    clipboardModel.clear()
    root.clipboardLoaded = false
    root.filterApps()
    clipboardRefreshTimer.restart()
  }

  function restoreClipboardEntry(line) {
    if (!line) return
    Quickshell.execDetached(["sh", "-c",
      "if command -v cliphist >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then printf '%s\\n' \"$1\" | cliphist decode | wl-copy; fi",
      "clipboard-restore", line])
    dismissed()
  }

  function clipboardPreviewForSelection() {
    if (!root.clipboardMode) return ""
    if (root.clipboardStatus !== "") return root.clipboardStatus
    if (filteredModel.count === 0) {
      return root.clipboardLoading ? "Loading clipboard history…" : "No clipboard history available"
    }
    if (root.selectedIndex < 0 || root.selectedIndex >= filteredModel.count) return ""
    var item = filteredModel.get(root.selectedIndex)
    if (item.kind === "clipboard-action") {
      return root.clipboardWipeArmed
        ? "Press Enter again to remove every saved clipboard entry"
        : "Remove every saved clipboard entry"
    }
    return item.kind === "clipboard" ? item.clipboardPreview : ""
  }

  function filterClipboardResults(query) {
    var matches = []
    for (var i = 0; i < clipboardModel.count; i++) {
      var item = clipboardModel.get(i)
      var score = scoreSpecialResult(item, query)
      if (score > 0) matches.push({ item: item, score: score })
    }

    var wipeAction = {
      kind: "clipboard-action",
      actionId: "clipboard-wipe",
      name: root.clipboardWipeRunning
        ? "Clearing clipboard history…"
        : (root.clipboardWipeArmed ? "Confirm clear clipboard history" : "Clear clipboard history"),
      comment: root.clipboardWipeRunning
        ? "Waiting for cliphist to finish"
        : (root.clipboardWipeArmed
        ? "Press Enter again to remove all saved entries"
        : "Remove all saved clipboard entries"),
      keywords: "clipboard clear wipe history delete",
      icon: root.clipboardWipeRunning ? "sync" : (root.clipboardWipeArmed ? "warning" : "delete_sweep")
    }
    var wipeScore = scoreSpecialResult(wipeAction, query)
    // Keep the destructive action available in the normal `;` view even when
    // the history is empty or the user has not typed a filter yet. A previous
    // score adjustment reduced the empty-query score to zero, which removed
    // the action from the model entirely.
    if (!query) {
      // Keep the action above the history entries so it remains reachable in
      // the constrained launcher viewport without requiring a long scroll.
      matches.push({ item: wipeAction, score: 2 })
    } else if (wipeScore > 0) {
      matches.push({ item: wipeAction, score: wipeScore })
    }

    matches.sort(function(a, b) {
      if (b.score !== a.score) return b.score - a.score
      return a.item.name.localeCompare(b.item.name)
    })

    for (var j = 0; j < matches.length; j++) appendFilteredResult(matches[j].item, matches[j].item.kind)
    selectedIndex = Math.max(0, Math.min(selectedIndex, filteredModel.count - 1))
  }

  function runAction(actionId) {
    switch (actionId) {
      case "quickmenu":
        runLauncherScript("quickmenu")
        break
      case "settings":
        runLauncherScript("settings")
        break
      case "lock":
        runLauncherScript("lock")
        break
      case "theme-auto":
        setThemeMode(0)
        break
      case "theme-light":
        setThemeMode(1)
        break
      case "theme-dark":
        setThemeMode(2)
        break
      case "clipboard-open":
        searchInputControl.text = ";"
        return
      case "capture-screen":
        runCaptureScript("screen")
        break
      case "capture-region":
        runCaptureScript("region")
        break
      case "clipboard-wipe":
        requestClipboardWipe()
        return
      default:
        return
    }
    dismissed()
  }

  function runCaptureScript(mode) {
    Quickshell.execDetached([
      "bash",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/capture-screen.sh",
      mode
    ])
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
    if (q.startsWith(";")) {
      filterClipboardResults(q.substring(1).trim())
      if (!clipboardLoaded && !clipboardProc.running) refreshClipboard()
      return
    }
    root.clipboardWipeArmed = false
    root.clipboardLoaded = false
    if (q === "") {
      for (var i = 0; i < appModel.count; i++) {
        appendFilteredResult(appModel.get(i), "app")
      }
      selectedIndex = 0
      return
    }

    var terms = q.split(/\s+/)
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
      var window = searchInputControl.Window.window
      if (window && !window.active && !resultMenu.opened) {
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
      clipboardModel.clear()
      clipboardLoaded = false
      clipboardLoading = false
      clipboardWipeArmed = false
      clipboardWipeRunning = false
      clipboardStatus = ""
      if (appModel.count > 0) {
        for (var i = 0; i < appModel.count; i++) {
          appendFilteredResult(appModel.get(i), "app")
        }
      }
      if (root.initialQuery !== "") {
        var q = root.initialQuery
        root.initialQuery = ""
        searchInputControl.text = q
        root.searchText = q
        root.selectedIndex = 0
        root.filterApps()
        searchInputControl.input.cursorPosition = q.length
      }
      if (Config.reducedMotion) {
        materialEntryAnimation.stop()
        scaleTransform.xScale = 1.0
        scaleTransform.yScale = 1.0
        transX.x = 0
        bg.opacity = 1.0
      } else {
        materialEntryAnimation.restart()
      }
    } else {
      // A query set while the launcher stayed hidden must not leak into the next open.
      root.initialQuery = ""
      resultMenu.close()
      if (clipboardProc.running) clipboardProc.running = false
      clipboardWipeTimer.stop()
      clipboardRefreshTimer.stop()
    }
  }

  Timer {
    id: clipboardWipeTimer
    interval: 5000
    repeat: false
    onTriggered: {
      root.clipboardWipeArmed = false
      if (root.clipboardMode) root.filterApps()
    }
  }

  Timer {
    id: clipboardRefreshTimer
    interval: 180
    repeat: false
    onTriggered: root.refreshClipboard()
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    color: Colors.surface
    // Her rofi window: 6 S border in x0, 12 S radius, no padding.
    radius: Config.dp(12)
    border.width: Config.dp(6)
    border.color: Colors.surfaceContainer

    transform: [
      Translate { id: transX; x: 0 },
      Scale { id: scaleTransform; origin.x: bg.width / 2; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
    ]

    MaterialEntrance {
      id: materialEntryAnimation
      surfaceTarget: bg
      scaleTarget: scaleTransform
      translationTarget: transX
    }

    ColumnLayout {
      id: clipItem
      anchors { fill: parent; margins: Config.dp(6) }
      spacing: 0

      Shortcut {
        sequence: "Ctrl+F"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: {
          searchInputControl.input.forceActiveFocus()
          searchInputControl.input.selectAll()
        }
      }
      Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: {
          if (resultMenu.opened) {
            resultMenu.close()
            searchInputControl.input.forceActiveFocus()
          } else root.dismissed()
        }
      }
      Shortcut {
        sequences: ["Shift+F10", "Menu"]
        context: Qt.WindowShortcut
        enabled: root.visible && root.selectedResult !== null
        onActivated: resultMenu.popup(appList, appList.width / 2, appList.height / 2)
      }
      // Her rofi keys: row up/down and element next/previous, accept.
      Shortcut {
        sequences: ["Ctrl+N", "Alt+J", "Tab"]
        context: Qt.WindowShortcut
        enabled: root.visible && !resultMenu.opened
        onActivated: root.moveSelection(1)
      }
      Shortcut {
        sequences: ["Ctrl+P", "Alt+K", "Backtab"]
        context: Qt.WindowShortcut
        enabled: root.visible && !resultMenu.opened
        onActivated: root.moveSelection(-1)
      }
      Shortcut {
        sequences: ["Ctrl+M", "Alt+M", "Alt+A"]
        context: Qt.WindowShortcut
        enabled: root.visible && !resultMenu.opened
        onActivated: root.activateSelection()
      }

      Menu {
        id: resultMenu
        width: Math.min(280, bg.width - Config.spacingMedium * 2)
        background: Rectangle {
          radius: Config.shapeMedium
          color: Colors.surfaceContainerHigh
          border.width: 1
          border.color: Colors.outlineVariant
        }
        DesktopMenuItem {
          text: root.selectionActionLabel
          enabled: root.selectedResult !== null
          onTriggered: root.activateSelection()
        }
        DesktopMenuItem {
          text: "Copy launch command"
          visible: root.selectedResult !== null && root.selectedResult.kind === "app"
          height: visible ? implicitHeight : 0
          enabled: visible && root.normalizeArgv(root.selectedResult.argv).length > 0
          onTriggered: Quickshell.execDetached(["wl-copy", "--", root.launchCommandText(root.selectedResult.argv)])
        }
        DesktopMenuItem {
          text: "Delete clipboard entry"
          visible: root.selectedResult !== null && root.selectedResult.kind === "clipboard"
          height: visible ? implicitHeight : 0
          onTriggered: root.deleteClipboardEntry(root.selectedResult.clipboardLine)
        }
      }

      // Her inputbar: 25 S padding, prompt glyph in x1, then the entry.
      TextFieldControl {
        id: searchInputControl
        objectName: "inputbar"
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        Layout.minimumHeight: implicitHeight
        Layout.margins: 0
        plain: true
        color: "transparent"
        leadingGlyph: "\ueca7"
        leadingGlyphColor: Colors.elenaAccent(1)
        leadingGlyphSize: root.textPx
        textPixelSize: root.textPx
        textBold: true
        sidePadding: Config.dp(25)
        verticalPadding: Config.dp(20)
        captureHorizontalArrows: false
        onLeftPressed: root.moveSelection(-1)
        onRightPressed: root.moveSelection(1)
        placeholder: root.actionMode ? "Run a shell action..."
          : (root.clipboardMode ? "Search clipboard history..." : "")
        showPlaceholderOnFocus: true
        accessibleName: "Search applications and launcher providers"

        onAccepted: root.activateSelection()
        onEscapePressed: root.dismissed()
        onUpPressed: root.moveSelection(-1)
        onDownPressed: root.moveSelection(1)
      }

      // Her message bar (x0): provider, match count and keys.
      Rectangle {
        objectName: "message"
        Layout.fillWidth: true
        Layout.preferredHeight: messageText.implicitHeight + 2 * Config.dp(6)
        color: Colors.surfaceContainer
        Text {
          id: messageText
          anchors.fill: parent
          anchors.leftMargin: Config.dp(30)
          anchors.rightMargin: Config.dp(30)
          verticalAlignment: Text.AlignVCenter
          text: "/ " + (root.actionMode ? "ACTIONS" : (root.clipboardMode ? "CLIPBOARD" : "APPLICATIONS")) + " /"
            + "   " + filteredModel.count + (filteredModel.count === 1 ? " MATCH" : " MATCHES")
            + "   ↑↓ SELECT · ENTER " + (root.clipboardMode ? "RESTORE" : (root.actionMode ? "RUN" : "OPEN"))
            + (root.searchText === "" ? "   > ACTIONS · ; CLIPBOARD · @ WALLPAPERS" : "")
          color: Colors.fgSurface
          font.family: "monospace"
          font.pixelSize: Math.round(root.textPx * 0.6)
          font.letterSpacing: Config.typeMonoTracking
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }

      Connections {
        target: searchInputControl.input
        function onTextChanged() {
          resultMenu.close()
          root.searchText = searchInputControl.text
          root.selectedIndex = 0
          root.filterApps()
        }
      }

      // Eight lines, no scrollbar; rows 10 S by 25 S padding, 2 S apart.
      ListView {
        id: appList
        objectName: "list"
        visible: true
        Layout.fillWidth: true
        Layout.preferredHeight: LauncherLayout.listHeight(root.rowHeight, Config.dp(2))
        Layout.minimumHeight: Layout.preferredHeight
        activeFocusOnTab: false
        Keys.onUpPressed: root.moveSelection(-1)
        Keys.onDownPressed: root.moveSelection(1)
        Keys.onReturnPressed: root.activateSelection()
        Keys.onEnterPressed: root.activateSelection()
        model: filteredModel
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex
        spacing: Config.dp(2)

        delegate: Rectangle {
          id: resultRow
          required property int index
          required property var model
          objectName: "row_" + index
          readonly property bool selected: root.selectedIndex === index
          width: appList.width
          height: root.rowHeight
          color: selected ? Colors.surfaceContainer : "transparent"
          Accessible.role: Accessible.ListItem
          Accessible.name: model.name
          Accessible.description: model.comment || (model.kind === "action" ? "Shell action" : "Application")

          Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Config.dp(25)
            anchors.right: parent.right
            anchors.rightMargin: Config.dp(25) + (deleteButton.visible ? deleteButton.width : 0)
            spacing: Config.dp(14)
            Text {
              id: nameText
              objectName: "name"
              text: resultRow.model.name
              color: resultRow.selected ? Colors.elenaAccent(4) : Colors.fgSurface
              font.family: "monospace"
              font.bold: true
              font.pixelSize: root.textPx
              elide: Text.ElideRight
              width: Math.min(implicitWidth, parent.width)
            }
            Text {
              visible: resultRow.selected && resultRow.model.comment !== ""
              text: resultRow.model.comment
              width: Math.max(0, parent.width - nameText.width - parent.spacing)
              color: Colors.elenaAccent(8)
              font.family: Config.fontFamily
              font.pixelSize: Math.round(root.textPx * 0.7)
              anchors.verticalCenter: parent.verticalCenter
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onEntered: if (!resultMenu.opened) root.selectedIndex = resultRow.index
            onClicked: function(m) {
              root.selectedIndex = resultRow.index
              if (m.button === Qt.RightButton) resultMenu.popup(resultRow, m.x, m.y)
              else root.activateSelection()
            }
          }

          IconButton {
            id: deleteButton
            visible: root.clipboardMode && resultRow.model.kind === "clipboard"
            anchors.right: parent.right
            anchors.rightMargin: Config.dp(10)
            anchors.verticalCenter: parent.verticalCenter
            size: 30
            iconSize: 18
            iconLabel: "delete"
            variant: "tonal"
            accessibleName: "Delete clipboard entry"
            accessibleDescription: "Delete this entry from clipboard history"
            tooltipText: "Delete clipboard entry"
            onClicked: root.deleteClipboardEntry(resultRow.model.clipboardLine)
          }
        }
      }

      Text {
        Layout.fillWidth: true
        Layout.margins: Config.dp(25)
        visible: !root.clipboardMode && filteredModel.count === 0
        text: "No matching results"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodyMediumSize
        wrapMode: Text.Wrap
      }

      Rectangle {
        id: clipboardPreview
        visible: root.clipboardMode
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        Layout.margins: Config.dp(10)
        radius: Config.shapeMedium
        color: Colors.surfaceContainerLow

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Config.spacingSmall
          spacing: 2

          Text {
            text: "SELECTED PREVIEW"
            color: Colors.fgSurfaceVariant
            font.family: "monospace"
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeMonoTracking
          }

          Text {
            Layout.fillWidth: true
            text: root.clipboardPreviewForSelection()
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodySmallSize
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
          }
        }
      }
    }
  }

  function moveSelection(delta) {
    if (filteredModel.count === 0) return
    selectedIndex = Math.max(0, Math.min(filteredModel.count - 1, selectedIndex + delta))
    ensureVisible(selectedIndex)
  }

  function ensureVisible(idx) {
    appList.positionViewAtIndex(idx, ListView.Contain)
  }
}
