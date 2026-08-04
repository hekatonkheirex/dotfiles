import QtQuick
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

  implicitWidth: Config.popupWidth
  visible: false
  implicitHeight: Math.min(clipItem.implicitHeight + 32, 500)
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
  ListModel { id: filteredModel }

  property string searchText: ""
  property int selectedIndex: 0
  property bool voiceRecording: false
  property bool voiceTranscribing: false

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

  function filterApps() {
    filteredModel.clear()
    var q = searchText.toLowerCase().trim()
    if (q === "") {
      for (var i = 0; i < appModel.count; i++) {
        filteredModel.append(appModel.get(i))
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
      filteredModel.append(matches[j].app)
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
          filteredModel.append(appModel.get(i))
        }
      }
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
          : (root.voiceTranscribing ? "Transcribing..." : "Search apps...")
        showPlaceholderOnFocus: true
        accessibleName: "Search applications"

        onAccepted: {
          if (filteredModel.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < filteredModel.count) {
            var app = filteredModel.get(root.selectedIndex)
            root.launchApp(app.exec, app.terminal)
          }
        }
        onEscapePressed: root.dismissed()
        onUpPressed: {
          root.selectedIndex = Math.max(0, root.selectedIndex - 1)
          root.ensureVisible(root.selectedIndex)
        }
        onDownPressed: {
          root.selectedIndex = Math.min(filteredModel.count - 1, root.selectedIndex + 1)
          root.ensureVisible(root.selectedIndex)
        }

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
        Layout.preferredHeight: Math.min(contentHeight, 380)
        model: filteredModel
        clip: true
        currentIndex: root.selectedIndex
        spacing: 4

        delegate: ListItem {
          width: appList.width
          height: 44
          radius: 22
          leadingImageSource: model.icon !== "" ? "file://" + model.icon : ""
          leadingFallbackText: model.icon === "" ? model.name.charAt(0).toUpperCase() : ""
          title: model.name
          subtitle: model.comment || ""
          selected: root.selectedIndex === index
          accessibleName: model.name
          accessibleDescription: model.comment || "Application"
          onHoveredChanged: {
            if (hovered) root.selectedIndex = index
          }
          onClicked: {
            root.selectedIndex = index
            root.launchApp(model.exec, model.terminal)
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
