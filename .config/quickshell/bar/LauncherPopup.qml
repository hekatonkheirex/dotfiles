import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  visible: false
  implicitHeight: Math.min(clipItem.implicitHeight + 32, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.focusable: true

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
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
          searchInput.text = t
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
      if (!Qt.application.active && root.visible && config && config.isNiri) root.dismissed()
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
    onTriggered: searchInput.forceActiveFocus()
  }

  Timer {
    id: focusCheck
    interval: 300
    running: visible
    repeat: true
    onTriggered: {
      if (!searchInput.activeFocus) {
        stop()
        dismissed()
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      searchInput.text = ""
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
    color: colors_ ? colors_.surfaceContainer : "#211F26"
    radius: 24
    border.color: colors_ ? colors_.outlineVariant : "#49454F"
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
        duration: 250
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: transX
        property: "x"
        from: -30
        to: 0
        duration: 250
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: bg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 200
        easing.type: Easing.OutCubic
      }
    }

    ColumnLayout {
      id: clipItem
      anchors { fill: parent; margins: 12 }
      spacing: 12

      // Pill-shaped search bar container
      Rectangle {
        id: searchBarContainer
        Layout.fillWidth: true
        height: 46
        radius: height / 2
        color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
        border.width: 1
        border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.1) : "transparent"

        RowLayout {
          anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
          spacing: 12

          Text {
            text: "search"
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 22
            Layout.alignment: Qt.AlignVCenter
          }

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: 16
            clip: true
            focus: true
            cursorVisible: true
            activeFocusOnPress: true
            selectByMouse: true

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.IBeamCursor
              acceptedButtons: Qt.NoButton
            }

            Text {
              text: root.voiceRecording ? "Listening... Click mic to stop." : (root.voiceTranscribing ? "Transcribing..." : "Search apps...")
              color: root.voiceRecording ? (colors_ ? colors_.error : "#ea1821") : (colors_ ? colors_.fgSurfaceVariant : "#888888")
              font.family: searchInput.font.family
              font.pixelSize: searchInput.font.pixelSize
              visible: searchInput.text === ""
            }

            onTextChanged: {
              root.searchText = text
              root.selectedIndex = 0
              filterApps()
            }

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                dismissed()
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (filteredModel.count > 0 && selectedIndex >= 0 && selectedIndex < filteredModel.count) {
                  var app = filteredModel.get(selectedIndex)
                  root.launchApp(app.exec, app.terminal)
                }
              } else if (event.key === Qt.Key_Up) {
                selectedIndex = Math.max(0, selectedIndex - 1)
                ensureVisible(selectedIndex)
              } else if (event.key === Qt.Key_Down) {
                selectedIndex = Math.min(filteredModel.count - 1, selectedIndex + 1)
                ensureVisible(selectedIndex)
              }
            }
          }

          Text {
            id: micIcon
            text: root.voiceRecording ? "stop" : (root.voiceTranscribing ? "sync" : "mic")
            color: root.voiceRecording ? (colors_ ? colors_.error : "#ea1821") : (root.voiceTranscribing ? (colors_ ? colors_.tertiary : "#FFD580") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"))
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 22
            Layout.alignment: Qt.AlignVCenter

            onRotationChanged: {
              if (!root.voiceTranscribing && rotation !== 0) {
                rotation = 0
              }
            }

            RotationAnimator {
              target: micIcon
              running: root.voiceTranscribing
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
      }

      ListView {
        id: appList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 380)
        model: filteredModel
        clip: true
        currentIndex: root.selectedIndex
        spacing: 4

        delegate: Rectangle {
          width: appList.width
          height: 48
          radius: 24 // Pill shape selection
          color: root.selectedIndex === index ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent"

          RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 12

            Rectangle {
              width: 30
              height: 30
              radius: 15 // Circle avatar/icon background
              color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"

              Image {
                anchors.centerIn: parent
                width: 20
                height: 20
                source: model.icon !== "" ? "file://" + model.icon : ""
                sourceSize.width: 20
                sourceSize.height: 20
                smooth: true
                fillMode: Image.PreserveAspectFit
                visible: model.icon !== ""
              }

              Text {
                anchors.centerIn: parent
                text: model.name.charAt(0).toUpperCase()
                color: colors_ ? colors_.fgSurface : "#FFFFFF"
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 14
                font.weight: Font.Medium
                visible: model.icon === ""
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                Layout.fillWidth: true
                text: model.name
                color: colors_ ? colors_.fgSurface : "#FFFFFF"
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                text: model.comment || ""
                color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                font.family: config ? config.fontFamily : "Google Sans Flex"
                font.pixelSize: 13
                elide: Text.ElideRight
                visible: text !== ""
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectedIndex = index
              root.launchApp(model.exec, model.terminal)
            }
            onEntered: { root.selectedIndex = index }
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
