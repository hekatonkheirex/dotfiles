import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

// Transient Ghost login splash. It runs once when the Quickshell session starts
// after SDDM, and can be replayed through the shell IPC endpoint.
PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  readonly property color glow: colors_ ? colors_.ghostCyan : "#57d9cc"
  readonly property color voidBg: colors_ ? colors_.ghostVoid : "#05080a"
  readonly property color mutedColor: colors_ ? colors_.ghostMuted : "#678984"
  readonly property color greenColor: colors_ ? colors_.ghostSuccess : "#8fe38a"
  readonly property color amberColor: colors_ ? colors_.ghostWarning : "#e0a94a"
  readonly property bool motionEnabled: !(config && config.reducedMotion)
  readonly property bool ghostSelected: !!(config && config.ghostTheme)
  readonly property bool signalFilterEngaged: Settings.doNotDisturb
  readonly property bool thermopticCamoActive: false
  readonly property string operatorLabel: "OPERATOR NODE"
  readonly property string userName: Quickshell.env("USER") || "user"

  // Cyberbrain boot trace. One imperative ticker drives every reveal binding;
  // reduced motion jumps straight to the completed trace and never ticks.
  property int bootTick: 0
  readonly property int bootTicksTotal: 34
  readonly property bool bootDone: bootTick >= bootTicksTotal
  readonly property var bootLines: [
    { jp: "電脳起動", en: "CYBERBRAIN BOOT", status: "OK", hot: false },
    { jp: "義体診断", en: "SHELL DIAGNOSTICS", status: "OK", hot: false },
    { jp: "ゴースト同期", en: "GHOST SYNC", status: "LOCKED", hot: false },
    { jp: "外部記憶", en: "EXTERNAL MEMORY", status: "MOUNTED", hot: false },
    { jp: "攻性防壁", en: "ATTACK BARRIER", status: "ARMED", hot: true },
    { jp: "光学迷彩", en: "THERMOPTIC CAMO", status: root.thermopticCamoActive ? "ACTIVE" : "STANDBY", hot: root.thermopticCamoActive },
    { jp: "着信制御", en: "SIGNAL FILTER", status: root.signalFilterEngaged ? "ENGAGED" : "OPEN", hot: root.signalFilterEngaged },
    { jp: "動作制限", en: "MOTION PROTOCOL", status: (config && config.reducedMotion) ? "REDUCED" : "FULL", hot: false },
    { jp: "公安9課接続", en: "SECTION 9 UPLINK", status: "ESTABLISHED", hot: false },
    { jp: "オペレーター認証", en: "OPERATOR AUTH", status: userName.toUpperCase(), hot: false }
  ]

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-welcome"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.focusable: root.visible

  anchors.left: true
  anchors.right: true
  anchors.top: true
  anchors.bottom: true

  visible: false
  property real screenOpacity: 0
  property real imageOpacity: 0
  Behavior on screenOpacity { NumberAnimation { duration: root.motionEnabled ? 250 : 0 } }

  NumberAnimation {
    id: fadeOut
    target: root
    property: "screenOpacity"
    to: 0
    duration: root.motionEnabled ? 400 : 0
    onStopped: if (root.screenOpacity === 0) root.visible = false
  }

  Timer {
    id: dismissTimer
    interval: 7500
    onTriggered: fadeOut.start()
  }

  // Boot ticker: started imperatively from show(), stops itself at the final
  // tick, and hands the greeting phase to the artwork animation. It never
  // declares an always-running state.
  Timer {
    id: bootTimer
    interval: 90
    repeat: true
    onTriggered: {
      root.bootTick += 1
      if (root.bootTick >= root.bootTicksTotal) {
        stop()
        briefImage.start()
      }
    }
  }

  SequentialAnimation {
    id: briefImage
    // show() starts this only when motion is enabled; keep the guard local too
    // so the reduced-motion contract is explicit at the animation boundary.
    onStarted: if (!root.motionEnabled) stop()
    NumberAnimation { target: root; property: "imageOpacity"; from: 0; to: 0.12; duration: 250; easing.type: Easing.OutQuad }
    PauseAnimation { duration: 1250 }
    NumberAnimation { target: root; property: "imageOpacity"; to: 0; duration: 500; easing.type: Easing.InQuad }
  }

  Timer {
    id: reducedMotionImageTimer
    interval: 2000
    onTriggered: root.imageOpacity = 0
  }

  function show() {
    if (!root.ghostSelected) return

    root.visible = true
    root.screenOpacity = 1
    briefImage.stop()
    reducedMotionImageTimer.stop()
    bootTimer.stop()
    root.imageOpacity = 0
    if (root.motionEnabled) {
      root.bootTick = 0
      bootTimer.restart()
    } else {
      root.bootTick = root.bootTicksTotal
      root.imageOpacity = 0.07
      reducedMotionImageTimer.start()
    }
    fadeOut.stop()
    dismissTimer.restart()
  }

  function dismiss() {
    dismissTimer.stop()
    bootTimer.stop()
    fadeOut.start()
  }

  Timer { id: showTimer; interval: 400; onTriggered: root.show() }
  // Start the short post-login delay unconditionally so a persisted Ghost
  // preference that finishes loading just after component creation is still
  // honored; show() itself gates the overlay to Ghost.
  Component.onCompleted: showTimer.start()

  Connections {
    target: Settings
    function onThemeStyleChanged() {
      if (!root.ghostSelected) root.dismiss()
    }
  }

  Item {
    id: content
    anchors.fill: parent
    opacity: root.screenOpacity

    Rectangle {
      anchors.fill: parent
      color: root.voidBg
    }

    Image {
      anchors.fill: parent
      source: "../resources/images/welcome-cyberbrain.png"
      fillMode: Image.PreserveAspectCrop
      sourceSize.width: 1122
      sourceSize.height: 1402
      asynchronous: true
      cache: true
      opacity: root.imageOpacity
    }

    // Sparse Section 9 corner brackets, matching the lock screen's frame language.
    Repeater {
      model: [
        { left: true, top: true }, { left: false, top: true },
        { left: true, top: false }, { left: false, top: false }
      ]
      Item {
        width: 52; height: 52
        anchors.left: modelData.left ? parent.left : undefined
        anchors.right: modelData.left ? undefined : parent.right
        anchors.top: modelData.top ? parent.top : undefined
        anchors.bottom: modelData.top ? undefined : parent.bottom
        anchors.margins: 28
        Rectangle { width: 52; height: 1; anchors.top: modelData.top ? parent.top : undefined; anchors.bottom: modelData.top ? undefined : parent.bottom; color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.6) }
        Rectangle { width: 1; height: 52; anchors.left: modelData.left ? parent.left : undefined; anchors.right: modelData.left ? undefined : parent.right; color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.6) }
      }
    }

    Rectangle {
      id: scanBeam
      width: parent.width
      height: 2
      color: root.glow
      opacity: 0.0
      SequentialAnimation on y {
        running: root.visible && root.motionEnabled
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: root.height; duration: 3400; easing.type: Easing.InOutQuad }
        PauseAnimation { duration: 700 }
      }
      SequentialAnimation on opacity {
        running: root.visible && root.motionEnabled
        loops: Animation.Infinite
        NumberAnimation { to: 0.45; duration: 300 }
        NumberAnimation { to: 0.45; duration: 2800 }
        NumberAnimation { to: 0.0; duration: 300 }
        PauseAnimation { duration: 700 }
      }
    }

    // Boot trace: fixed layout, lines pop in place (opacity bindings, no layout
    // shift, no per-line animation blocks). Dims once the greeting takes over.
    Column {
      id: bootLog
      anchors.left: parent.left
      anchors.leftMargin: 72
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: -30
      spacing: 6
      // Hard pop between full and dimmed, like every trace line: a Behavior
      // here would replay stale state when show() resets bootTick.
      opacity: root.bootDone ? 0.45 : 1.0

      Text {
        text: "SECTION 9 // BOOT TRACE"
        font.family: "IBM Plex Mono"
        font.pixelSize: 10
        font.letterSpacing: 1.5
        color: root.glow
        opacity: 0.85
      }

      Item { width: 1; height: 4 }

      Repeater {
        model: root.bootLines
        Row {
          id: traceLine
          readonly property string fullLabel: modelData.jp + " // " + modelData.en
          // Per-character typing off the shared ticker: each line types over
          // three ticks, then its status resolves two ticks later. No per-line
          // timers or animation blocks; fixed row height so nothing shifts.
          readonly property int typedChars: Math.max(0, Math.min(fullLabel.length, Math.ceil((root.bootTick - index * 3) * fullLabel.length / 3)))
          readonly property bool statusResolved: root.bootTick >= index * 3 + 5
          Item {
            width: 330
            height: 15
            Text {
              id: lineLabel
              anchors.left: parent.left
              text: traceLine.fullLabel.substring(0, traceLine.typedChars)
              font.family: "Noto Sans CJK JP"
              font.pixelSize: 10
              font.letterSpacing: 1
              color: root.mutedColor
            }
          }
          Text {
            text: traceLine.statusResolved ? modelData.status : (root.bootTick >= index * 3 ? "...." : "")
            font.family: "IBM Plex Mono"
            font.pixelSize: 10
            font.letterSpacing: 1
            color: traceLine.statusResolved ? (modelData.hot ? root.amberColor : root.greenColor) : root.mutedColor
          }
        }
      }

      Item { width: 1; height: 8 }

      Row {
        spacing: 10
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 240
          height: 3
          color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.16)
          Rectangle {
            width: Math.min(1, root.bootTick / root.bootTicksTotal) * parent.width
            height: parent.height
            color: root.glow
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Math.round(Math.min(1, root.bootTick / root.bootTicksTotal) * 100) + "%"
          font.family: "IBM Plex Mono"
          font.pixelSize: 10
          color: root.glow
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: !root.bootDone
          text: "▊"
          font.family: "IBM Plex Mono"
          font.pixelSize: 10
          color: root.glow
          SequentialAnimation on opacity {
            running: root.visible && root.motionEnabled && !root.bootDone
            loops: Animation.Infinite
            NumberAnimation { to: 0.1; duration: 260 }
            NumberAnimation { to: 1.0; duration: 260 }
          }
        }
      }
    }

    Item {
      id: focusScope
      anchors.fill: parent
      focus: root.visible
      Keys.onPressed: function(event) { root.dismiss(); event.accepted = true }

      MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
      }

      Column {
        anchors.centerIn: parent
        spacing: 16
        // The greeting holds until the boot trace resolves; reduced motion
        // arrives with bootDone already true, so it renders immediately.
        // Hard pop on reveal, deliberately unanimated: the simultaneous artwork
        // fade supplies the softness, and a Behavior would fade the stale
        // greeting over a fresh boot log on IPC replay.
        opacity: root.bootDone ? 1 : 0

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "THE NET IS VAST AND INFINITE"
          font.family: "Rajdhani"
          font.pixelSize: 64
          font.weight: Font.Bold
          font.letterSpacing: 4
          color: root.glow
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "SECTION 9 // CYBERBRAIN LINK ESTABLISHED"
          font.family: "IBM Plex Mono"
          font.pixelSize: 13
          font.letterSpacing: 1.5
          color: root.mutedColor
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.operatorLabel + " // " + root.userName.toUpperCase() + " // GHOST ONLINE"
          font.family: "IBM Plex Mono"
          font.pixelSize: 11
          font.letterSpacing: 1
          color: root.mutedColor
          opacity: 0.8
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        text: "CLICK OR PRESS ANY KEY TO CONTINUE"
        font.family: "IBM Plex Mono"
        font.pixelSize: 10
        font.letterSpacing: 1
        color: root.mutedColor
        opacity: 0.5
      }
    }
  }
}
