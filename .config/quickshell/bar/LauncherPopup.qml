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

PanelWindow {
  id: root

  property int anchorY: 0
  // dwm theme: the launcher becomes a one-line strip drawn over a horizontal bar.
  property bool barHorizontal: true
  readonly property bool dmenu: Config.dwmTheme && root.barHorizontal
  onDmenuChanged: if (visible) focusTimer.restart()

  readonly property string runtimeDirectory: {
    var xdgRuntime = Quickshell.env("XDG_RUNTIME_DIR")
    return xdgRuntime
      ? xdgRuntime + "/quickshell"
      : Quickshell.env("HOME") + "/.cache/quickshell/runtime"
  }
  readonly property string voiceFilePath: root.runtimeDirectory + "/voice-search.wav"

  signal dismissed()
  // "@" hands off to the full-width wallpaper filmstrip; the text typed after
  // it travels along as the initial jump query.
  signal wallpapersRequested(string query)


  implicitWidth: root.dmenu ? 0 : Math.min(Config.launcherWidth,
    Math.max(240, Screen.desktopAvailableWidth - Config.barWidth - Config.spacingPage))
  visible: false
  implicitHeight: root.dmenu ? Config.barWidth
    : Math.min(screenH - Config.spacingPage, clipItem.implicitHeight + Config.spacingPage,
        clipboardMode ? 620 : 500)

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
  WlrLayershell.layer: root.dmenu ? WlrLayer.Overlay : WlrLayer.Top
  WlrLayershell.focusable: true
  WlrLayershell.keyboardFocus: root.dmenu ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

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
  property bool voiceRecording: false
  property bool voiceTranscribing: false
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

  Process {
    id: recorderProc
    command: [
      "sh", "-c",
      "mkdir -p -- \"$1\" && (chmod 700 -- \"$1\" 2>/dev/null || [ \"$(stat -c %a -- \"$1\" 2>/dev/null)\" = 700 ]) && exec pw-record --rate 16000 --channels 1 --format s16 \"$2\"",
      "sh", root.runtimeDirectory, root.voiceFilePath
    ]
    running: false
  }

  Process {
    id: transcriberProc
    command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/voice-search.py", root.voiceFilePath]
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
        searchInputControl.input.forceActiveFocus()
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

  function toggleVoiceSearch() {
    if (!root.voiceRecording && !root.voiceTranscribing) {
      root.voiceRecording = true
      Quickshell.execDetached(["rm", "-f", root.voiceFilePath])
      recorderProc.running = true
    } else if (root.voiceRecording) {
      root.voiceRecording = false
      root.voiceTranscribing = true
      recorderProc.running = false
      transcriberProc.running = true
    }
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
      if (window && !window.active && !resultMenu.opened
          && !root.voiceRecording && !root.voiceTranscribing) {
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
      if (Config.reducedMotion || root.dmenu) {
        entryAnimation.stop()
        materialEntryAnimation.stop()
        reducedMotionEntryAnimation.stop()
        scaleTransform.xScale = 1.0
        scaleTransform.yScale = 1.0
        transX.x = 0
        if (Config.liquidGlassTheme) {
          bg.opacity = 0.0
          reducedMotionEntryAnimation.start()
        } else {
          bg.opacity = 1.0
        }
      } else if (Config.material3Theme) {
        materialEntryAnimation.restart()
      } else {
        entryAnimation.start()
      }
      root.voiceRecording = false
      root.voiceTranscribing = false
    } else {
      resultMenu.close()
      if (root.voiceRecording) {
        root.voiceRecording = false
        recorderProc.running = false
      }
      if (root.voiceTranscribing) {
        root.voiceTranscribing = false
        transcriberProc.running = false
      }
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
    color: root.dmenu ? Colors.styleSurface
      : (Config.nothingEvolution ? Colors.readingSurface
      : (Config.liquidGlassTheme
        ? Colors.chromeSurface
        : ((Config.nothingDesign || Config.ghostTheme)
          ? Colors.styleSurfaceRaised : Colors.surfaceContainer)))
    radius: root.dmenu ? 0 : Config.popupRadius
    border.color: Colors.styleOutline
    border.width: root.dmenu ? 0 : Config.themeBorderWidth

    GlassSheen {
      anchors.fill: parent
      radius: parent.radius
    }

    transform: [
      Translate { id: transX; x: 0 },
      Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
    ]

    MaterialEntrance {
      id: materialEntryAnimation
      surfaceTarget: bg
      scaleTarget: scaleTransform
      translationTarget: transX
    }

    ParallelAnimation {
      id: entryAnimation
      NumberAnimation {
        target: scaleTransform
        properties: "xScale,yScale"
        from: Config.surfaceEntryScale
        to: 1.0
        duration: Config.surfaceEntryDuration
        easing.type: Config.themeMotionEasing
      }
      NumberAnimation {
        target: transX
        property: "x"
        from: Config.surfaceEntryOffset
        to: 0
        duration: Config.surfaceEntryDuration
        easing.type: Config.themeMotionEasing
      }
      NumberAnimation {
        target: bg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: Config.surfaceOpacityDuration
        easing.type: Easing.OutCubic
      }
    }

    NumberAnimation {
      id: reducedMotionEntryAnimation
      target: bg
      property: "opacity"
      from: 0.0
      to: 1.0
      duration: Config.reducedMotionFadeDuration
      easing.type: Easing.OutCubic
    }

    // dmenu strip: prompt, input, then results inline. The search field is the
    // same TextFieldControl the list view uses; it is reparented here so focus,
    // filtering and launch logic stay in one place.
    RowLayout {
      id: dmenuRow
      visible: root.dmenu
      anchors.fill: parent
      spacing: 0

      Text {
        id: dmenuPrompt
        Layout.fillHeight: true
        Layout.preferredWidth: implicitWidth + Config.spacingMedium * 2
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.clipboardMode ? "clip" : "run"
        color: Colors.fgPrimary
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        Rectangle {
          anchors.fill: parent
          z: -1
          color: Colors.primary
        }
      }

      // searchInputControl is reparented here when root.dmenu is true.
      Item {
        id: dmenuInputSlot
        Layout.preferredWidth: Math.min(280, Math.round(root.width / 3))
        Layout.fillHeight: true
      }

      Text {
        visible: !appStrip.atXBeginning && filteredModel.count > 0
        text: "<"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        Layout.leftMargin: Config.spacingSmall
        Layout.rightMargin: Config.spacingCompact
      }

      ListView {
        id: appStrip
        Layout.fillWidth: true
        Layout.fillHeight: true
        orientation: ListView.Horizontal
        clip: true
        interactive: false
        model: root.dmenu ? filteredModel : null
        currentIndex: root.selectedIndex
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Rectangle {
          required property int index
          required property var model
          readonly property bool current: root.selectedIndex === index
          height: appStrip.height
          width: stripLabel.implicitWidth + Config.spacingMedium * 2
          color: current ? Colors.primary : "transparent"

          Text {
            id: stripLabel
            anchors.centerIn: parent
            text: model.name
            color: parent.current ? Colors.fgPrimary : Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelMediumSize
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              root.selectedIndex = index
              root.activateSelection()
            }
          }
        }
      }

      Text {
        visible: !appStrip.atXEnd && filteredModel.count > 0
        text: ">"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        Layout.leftMargin: Config.spacingCompact
        Layout.rightMargin: Config.spacingSmall
      }
    }

    ColumnLayout {
      id: clipItem
      anchors { fill: parent; margins: Config.spacingMedium }

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
        enabled: root.visible && root.selectedResult !== null && !root.dmenu
        onActivated: resultMenu.popup(appList, appList.width / 2, appList.height / 2)
      }

      Menu {
        id: resultMenu
        width: Math.min(280, bg.width - Config.spacingMedium * 2)
        background: Rectangle {
          radius: Config.shapeMedium
          color: Colors.surfaceContainerHigh
          border.width: 1
          border.color: Colors.styleOutline
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
      spacing: Config.spacingMedium

      // List-view slot for searchInputControl. It sizes like the field did as a
      // direct layout child: preferred = implicitHeight, minimum = Material's.
      Item {
        id: listInputSlot
        visible: !root.dmenu
        Layout.fillWidth: true
        Layout.preferredHeight: searchInputControl.implicitHeight
        Layout.minimumHeight: Config.material3Theme ? searchInputControl.implicitHeight : 0
      }

      TextFieldControl {
        id: searchInputControl
        // Reparenting appends to the new parent's children and layouts place
        // children in that order, so the field lives in a plain slot Item in
        // each layout instead of being a layout child itself.
        parent: root.dmenu ? dmenuInputSlot : listInputSlot
        width: parent.width
        // Strip: fixed third-width input, no icon, no frame, arrows move selection.
        height: parent.height
        // Reproduces TextFieldControl's own color binding for every non-dmenu style.
        color: root.dmenu ? "transparent"
          : (Config.material3Theme ? Colors.surface
            : (Config.liquidGlassTheme ? Colors.liquidGlassControl : Colors.styleSurface))
        border.width: root.dmenu ? 0
          : (searchInputControl.input.activeFocus ? Config.themeFocusBorderWidth : Config.themeBorderWidth)
        leadingIcon: root.dmenu ? "" : "search"
        captureHorizontalArrows: root.dmenu
        onLeftPressed: root.moveSelection(-1)
        onRightPressed: root.moveSelection(1)
        leadingIconSize: 22
        placeholder: root.voiceRecording
          ? "Listening... Click mic to stop."
          : (root.voiceTranscribing
            ? "Transcribing..."
            : (root.actionMode
              ? "Run a shell action..."
              : (root.clipboardMode ? "Search clipboard history..." : "Search apps")))
        showPlaceholderOnFocus: true
        accessibleName: "Search applications and launcher providers"

        onAccepted: root.activateSelection()
        onEscapePressed: root.dismissed()
        onUpPressed: root.moveSelection(-1)
        onDownPressed: root.moveSelection(1)

        IconButton {
          id: micIcon
          visible: !root.dmenu
          size: 32
          iconSize: 22
          iconLabel: root.voiceRecording ? "stop" : (root.voiceTranscribing ? "sync" : "mic")
          iconColor: root.voiceRecording ? Colors.destructive : (root.voiceTranscribing ? Colors.info : Colors.fgSurfaceVariant)
          accessibleName: root.voiceRecording
            ? "Stop voice search"
            : (root.voiceTranscribing ? "Transcribing voice search" : "Start voice search")
          accessibleDescription: root.voiceTranscribing
            ? "Voice search is being transcribed"
            : "Record a voice query for the launcher"
          tooltipText: accessibleName
          onClicked: root.toggleVoiceSearch()
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

        }
      }

      // Prefix shortcuts live under the field instead of crowding the placeholder.
      Flow {
        id: prefixChips
        Layout.fillWidth: true
        Layout.leftMargin: Config.spacingSmall
        spacing: Config.spacingSmall
        visible: !root.dmenu && root.searchText === "" && !root.voiceRecording && !root.voiceTranscribing

        Repeater {
          model: [
            { key: ">", label: "actions" },
            { key: ";", label: "clipboard" },
            { key: "@", label: "wallpapers" }
          ]
          delegate: ActionButton {
            required property var modelData
            height: Config.material3Theme ? implicitHeight : 32
            width: chipMetrics.width + Config.spacingMedium * 2
            labelText: modelData.key + "  " + modelData.label
            horizontalContent: true
            variant: "outlined"
            accessibleName: "Search " + modelData.label
            TextMetrics {
              id: chipMetrics
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              text: modelData.key + "  " + modelData.label
            }
            onActivated: {
              searchInputControl.text = modelData.key
              searchInputControl.input.forceActiveFocus()
            }
          }
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

      ListView {
        id: appList
        visible: !root.dmenu
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 380)
        Layout.fillHeight: true
        Layout.minimumHeight: 0
        activeFocusOnTab: true
        Keys.onUpPressed: root.moveSelection(-1)
        Keys.onDownPressed: root.moveSelection(1)
        Keys.onReturnPressed: root.activateSelection()
        Keys.onEnterPressed: root.activateSelection()
        model: filteredModel
        clip: true
        currentIndex: root.selectedIndex
        spacing: Config.spacingCompact
        ScrollBar.vertical: SettingsScrollBar { scrollTarget: appList }

        delegate: ListItem {
          id: resultRow
          contextMenuEnabled: true
          activeFocusOnTab: false
          Keys.onUpPressed: { root.moveSelection(-1); appList.forceActiveFocus() }
          Keys.onDownPressed: { root.moveSelection(1); appList.forceActiveFocus() }
          // The scrollbar is overlaid on the ListView; leave a gutter so a
          // selected row's rounded border cannot run underneath its thumb.
          width: Math.max(0, appList.width - Config.spacingMedium)
          height: Config.material3Theme ? implicitHeight : (root.clipboardMode ? 54 : 44)
          radius: Config.nothingDesign || Config.ghostTheme ? Config.shapeMedium : 22
          // Apps without a resolvable icon get a generic glyph, not a letter avatar.
          leadingIcon: model.kind === "action"
            || model.kind === "clipboard-action" || model.kind === "clipboard" ? model.icon
            : (model.icon === "" ? "apps" : "")
          leadingImageSource: model.kind !== "action" && model.icon !== ""
            && model.kind !== "clipboard-action" && model.kind !== "clipboard"
            ? "file://" + model.icon : ""
          title: model.name
          subtitle: Config.material3Theme && root.selectedIndex !== index ? "" : (model.comment || "")
          selected: root.selectedIndex === index
          accessibleName: model.name
          accessibleDescription: model.comment || (model.kind === "action" ? "Shell action" : "Application")
          onHoveredChanged: {
            if (hovered && !resultMenu.opened) root.selectedIndex = index
          }
          onClicked: {
            root.selectedIndex = index
            root.activateSelection()
          }
          onContextMenuRequested: function(mouse) {
            root.selectedIndex = index
            resultMenu.popup(resultRow, mouse.x, mouse.y)
          }

          IconButton {
            visible: root.clipboardMode && model.kind === "clipboard"
            size: 30
            iconSize: 18
            iconLabel: "delete"
            variant: "tonal"
            accessibleName: "Delete clipboard entry"
            accessibleDescription: "Delete this entry from clipboard history"
            tooltipText: "Delete clipboard entry"
            onClicked: root.deleteClipboardEntry(model.clipboardLine)
          }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: !root.dmenu && !root.clipboardMode && filteredModel.count === 0
        text: "No matching results"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodyMediumSize
        wrapMode: Text.Wrap
      }

      Rectangle {
        id: clipboardPreview
        visible: !root.dmenu && root.clipboardMode
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        radius: Config.shapeMedium
        color: Config.nothingDesign || Config.ghostTheme || Config.liquidGlassTheme
          ? Colors.styleSurface
          : Colors.surfaceContainerLow
        border.color: Colors.styleOutline
        border.width: Config.themeBorderWidth

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Config.spacingSmall
          spacing: 2

          Text {
            text: "Selected preview"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Font.Medium
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
    if (root.dmenu) appStrip.positionViewAtIndex(idx, ListView.Contain)
    else appList.positionViewAtIndex(idx, ListView.Contain)
  }
}
