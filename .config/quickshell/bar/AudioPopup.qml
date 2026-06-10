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
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 400)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))
  property real volume: 0.5
  property bool muted: false
  property real micVolume: 0.5
  property bool micMuted: false

  function setVolume(val) {
    root.volume = Math.max(0, Math.min(1, val))
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.volume)])
  }

  function toggleMute() {
    root.muted = !root.muted
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"])
  }

  function setMicVolume(val) {
    root.micVolume = Math.max(0, Math.min(1, val))
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(root.micVolume)])
  }

  function toggleMicMute() {
    root.micMuted = !root.micMuted
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.micMuted ? "1" : "0"])
  }

  Process {
    id: audioQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.volume = parseFloat(m[1])
        root.muted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  Process {
    id: micQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.micVolume = parseFloat(m[1])
        root.micMuted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  function pollAudio() { audioQuery.running = true; micQuery.running = true }

  Timer {
    interval: 600
    running: root.visible
    repeat: true
    onTriggered: root.pollAudio()
  }

  onVisibleChanged: {
    if (root.visible) {
      root.pollAudio()
      entryAnimation.start()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      config: root.config
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true

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

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: config ? config.popupPadding : 16
        }
        spacing: 16

        Text {
          text: "Volume"
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 8) : 18
          font.weight: Font.Bold
        }

        Text {
          text: muted ? "Muted" : Math.round(volume * 100) + "%"
          color: muted ? (colors_ ? colors_.error : "#F2B8B5") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 4) : 14
        }

        SliderControl {
          value: root.volume
          muted: root.muted
          activeColor: colors_ ? colors_.primary : "#D0BCFF"
          surfaceContainerHigh: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
          surfaceContainerHighest: colors_ ? colors_.surfaceContainerHighest : "#36343B"
          outline: colors_ ? colors_.outline : "#938F99"
          onChanged: function(val) { root.setVolume(val) }
        }

        Row {
          spacing: 8

          Rectangle {
            width: muteBtn.implicitWidth + 24
            height: 36
            radius: config ? config.borderRadius : 14
            color: colors_ ? (muteArea.containsMouse ? colors_.surfaceContainerHighest : colors_.surfaceContainer) : "#211F26"
            border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Text {
              id: muteBtn
              anchors.centerIn: parent
              text: root.muted ? "Unmute" : "Mute"
              color: colors_ ? colors_.fgSurface : "#FFFFFF"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 2) : 12
              font.weight: Font.Medium
            }

            MouseArea {
              id: muteArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleMute()
            }
          }

        }

        Rectangle {
          width: parent.width
          height: 1
          color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
        }

        Text {
          text: "Microphone"
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 8) : 18
          font.weight: Font.Bold
        }

        Text {
          text: micMuted ? "Muted" : Math.round(micVolume * 100) + "%"
          color: micMuted ? (colors_ ? colors_.error : "#F2B8B5") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 4) : 14
        }

        SliderControl {
          value: root.micVolume
          muted: root.micMuted
          activeColor: colors_ ? colors_.tertiary : "#D0BCFF"
          surfaceContainerHigh: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
          surfaceContainerHighest: colors_ ? colors_.surfaceContainerHighest : "#36343B"
          outline: colors_ ? colors_.outline : "#938F99"
          onChanged: function(val) { root.setMicVolume(val) }
        }

        Row {
          spacing: 8

          Rectangle {
            width: micMuteBtn.implicitWidth + 24
            height: 36
            radius: config ? config.borderRadius : 14
            color: colors_ ? (micMuteArea.containsMouse ? colors_.surfaceContainerHighest : colors_.surfaceContainer) : "#211F26"
            border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Text {
              id: micMuteBtn
              anchors.centerIn: parent
              text: root.micMuted ? "Unmute" : "Mute"
              color: colors_ ? colors_.fgSurface : "#FFFFFF"
              font.family: config ? config.fontFamily : "Google Sans Flex"
              font.pixelSize: config ? (config.fontPixelSize + 2) : 12
              font.weight: Font.Medium
            }

            MouseArea {
              id: micMuteArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleMicMute()
            }
          }
        }
      }
    }
  }
}
