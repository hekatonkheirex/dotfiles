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

  property int activePowerIndex: -1
  property int pendingPowerIndex: -1
  property var powerOptions: [
    { label: "Log Out", cmd: ["sh", Quickshell.env("HOME") + "/.config/quickshell/scripts/safe-logout.sh"] },
    { label: "Shut Down", cmd: ["systemctl", "poweroff"] },
    { label: "Restart", cmd: ["systemctl", "reboot"] },
    { label: "Sleep", cmd: ["systemctl", "suspend"] }
  ]
  property string focusWindowId: ""
  property bool focusWindowBaselineReady: false
  property bool focusDismissArmed: false
  property double openTime: 0

  signal lockRequested()

  property bool caffeineOn: false
  property bool airplaneOn: false

  Process {
    id: idleCheck
    command: ["sh", "-c", "pgrep -x swayidle >/dev/null 2>&1 && echo active || echo inactive"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.caffeineOn = text.trim() !== "active"
      }
    }
  }

  Process {
    id: airplaneCheck
    command: ["sh", "-c", "nmcli radio wifi | grep -q 'disabled' && echo on || echo off"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.airplaneOn = text.trim() === "on"
      }
    }
  }

  function toggleCaffeine() {
    if (root.caffeineOn) {
      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
      root.caffeineOn = false
    } else {
      Quickshell.execDetached(["killall", "swayidle"])
      root.caffeineOn = true
    }
  }

  function toggleAirplane() {
    var newState = !root.airplaneOn
    var cmd = newState
      ? "nmcli radio wifi off; bluetoothctl power off"
      : "nmcli radio wifi on; bluetoothctl power on"
    Quickshell.execDetached(["sh", "-c", cmd])
    root.airplaneOn = newState
  }

  function focusPower(index) {
    root.activePowerIndex = index
    var item = powerRepeater.itemAt(index)
    if (item) item.forceActiveFocus()
  }

  function powerIcon(label) {
    var icons = { "Sleep": "bedtime", "Restart": "restart_alt", "Shut Down": "power_settings_new", "Log Out": "logout" }
    return icons[label] || "power_settings_new"
  }

  function powerDescription(label) {
    var descriptions = {
      "Sleep": "The computer will enter suspend mode.",
      "Restart": "The computer will restart.",
      "Shut Down": "The computer will power off.",
      "Log Out": "Your current session will end."
    }
    return descriptions[label] || "This action will take effect immediately."
  }

  function requestPower(index) {
    if (index < 0 || index >= root.powerOptions.length) return
    // ponytail: close Quick Settings immediately instead of keeping it open
    // behind the confirmation dialog. Two layer-shell surfaces fighting over
    // OnDemand keyboard focus (confirmation steals it, then niri won't hand
    // it back to Quick Settings on cancel) made "click/Escape to dismiss"
    // unreliable. One popup on screen at a time sidesteps that entirely.
    root.activePowerIndex = index
    root.pendingPowerIndex = index
    root.dismissed()
  }

  function cancelPower() {
    root.pendingPowerIndex = -1
  }

  function confirmPower() {
    var index = root.pendingPowerIndex
    if (index < 0 || index >= root.powerOptions.length) {
      root.cancelPower()
      return
    }

    var option = root.powerOptions[index]
    root.pendingPowerIndex = -1
    Quickshell.execDetached(option.cmd)
  }

  readonly property int neoShadowPadding: Config.neoBrutalism ? Config.themeShadowOffset : 0

  implicitWidth: Config.popupWidth + neoShadowPadding
  visible: false
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 500) + neoShadowPadding
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: Config.barWidth + 4
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  Process {
    id: focusedWindowQuery
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j focused-window"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var raw = text.trim()
        var currentId = ""

        if (raw && raw !== "null") {
          try {
            var data = JSON.parse(raw)
            if (data && data.id !== undefined && data.id !== null) currentId = String(data.id)
          } catch (e) {
            currentId = ""
          }
        }

        if (!root.focusWindowBaselineReady || !root.focusDismissArmed) {
          root.focusWindowId = currentId
          root.focusWindowBaselineReady = true
          if (!root.focusDismissArmed) focusQueryDebounce.restart()
        } else if (root.visible && currentId !== root.focusWindowId) {
          root.dismissed()
        }
      }
    }
  }

  Timer {
    id: focusQueryDebounce
    interval: 80
    repeat: false
    onTriggered: {
      if (root.visible && Config.isNiri && !focusedWindowQuery.running) {
        focusedWindowQuery.running = true
      }
    }
  }

  Timer {
    id: focusDismissArmTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (!root.visible || !Config.isNiri) return
      root.focusDismissArmed = true
      root.focusWindowBaselineReady = false
      if (!focusedWindowQuery.running) focusedWindowQuery.running = true
    }
  }

  Process {
    id: focusEventWatcher
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg event-stream"]
    running: root.visible && Config.isNiri

    stdout: SplitParser {
      onRead: function(data) {
        if (root.visible && root.focusWindowBaselineReady) focusQueryDebounce.restart()
      }
    }

    onRunningChanged: {
      if (!running && root.visible && Config.isNiri) focusEventWatcherRetry.start()
    }
  }

  Timer {
    id: focusEventWatcherRetry
    interval: 1000
    repeat: false
    onTriggered: {
      if (root.visible && Config.isNiri) focusEventWatcher.running = true
    }
  }

  onVisibleChanged: {
    focusQueryDebounce.stop()
    focusEventWatcherRetry.stop()
    focusDismissArmTimer.stop()
    if (visible) {
      entryAnimation.start()
      root.activePowerIndex = -1
      root.pendingPowerIndex = -1
      root.focusWindowId = ""
      root.focusWindowBaselineReady = false
      root.focusDismissArmed = false
      mainItem.forceActiveFocus()
      root.openTime = Date.now()
      idleCheck.running = true
      airplaneCheck.running = true
      if (Config.isNiri) {
        focusedWindowQuery.running = true
        focusDismissArmTimer.restart()
      }
    } else {
      // pendingPowerIndex is intentionally left as-is here: requestPower()
      // closes this popup while the confirmation dialog takes over, and it
      // owns clearing pendingPowerIndex itself (via cancelPower/confirmPower).
      root.focusWindowId = ""
      root.focusWindowBaselineReady = false
      root.focusDismissArmed = false
      if (focusedWindowQuery.running) focusedWindowQuery.running = false
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Config.isNiri && !Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    id: mainItem
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (Date.now() - root.openTime > 150) {
          root.dismissed()
        }
        event.accepted = true
      } else if (event.key === Qt.Key_Left) {
        var len = root.powerOptions.length;
        var nextIndex = (root.activePowerIndex === -1) ? 0 : (root.activePowerIndex === len - 1 ? 0 : root.activePowerIndex + 1);
        root.focusPower(nextIndex)
        event.accepted = true
      } else if (event.key === Qt.Key_Right) {
        var len = root.powerOptions.length;
        var nextIndex = (root.activePowerIndex === -1) ? len - 1 : (root.activePowerIndex === 0 ? len - 1 : root.activePowerIndex - 1);
        root.focusPower(nextIndex)
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (root.activePowerIndex >= 0 && root.activePowerIndex < root.powerOptions.length) {
          root.requestPower(root.activePowerIndex)
          event.accepted = true
        }
      }
    }

    Rectangle {
      id: styleShadow
      x: Config.themeShadowOffset
      y: Config.themeShadowOffset
      width: bg.width
      height: bg.height
      radius: bg.radius
      color: Colors.styleShadow
      visible: Config.neoBrutalism
      z: -1
    }

    Rectangle {
      id: bg
      anchors {
        left: parent.left
        top: parent.top
        right: parent.right
        bottom: parent.bottom
        rightMargin: root.neoShadowPadding
        bottomMargin: root.neoShadowPadding
      }
      radius: Config.borderRadius
      color: Config.neoBrutalism ? Colors.styleSurface : Colors.surfaceContainerHigh
      clip: true
      border.width: Config.themeBorderWidth
      border.color: Colors.styleOutline

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

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: Config.popupPadding
        }
        spacing: 14

        Text {
          text: "Power Options"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 8)
          font.weight: Font.Bold
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)
        }

      Row {
        spacing: 8
        width: parent.width
        layoutDirection: Qt.RightToLeft

        ActionButton {
          width: (parent.width - 3 * 8) / 4
          height: width
          iconLabel: "coffee"
          labelText: "Caffeine"
          selected: root.caffeineOn
          accessibleName: "Caffeine mode"
          accessibleDescription: root.caffeineOn ? "Enabled" : "Disabled"
          onActivated: root.toggleCaffeine()
        }

        ActionButton {
          width: (parent.width - 3 * 8) / 4
          height: width
          iconLabel: root.airplaneOn ? "airplanemode_active" : "airplanemode_inactive"
          labelText: "Airplane"
          selected: root.airplaneOn
          accessibleName: "Airplane mode"
          accessibleDescription: root.airplaneOn ? "Enabled" : "Disabled"
          onActivated: root.toggleAirplane()
        }

        ActionButton {
          width: (parent.width - 3 * 8) / 4
          height: width
          iconLabel: "do_not_disturb_on"
          labelText: "DND"
          selected: Settings.doNotDisturb
          accessibleName: "Do Not Disturb"
          accessibleDescription: Settings.doNotDisturb
            ? "Enabled; toast popups suppressed and history retained"
            : "Disabled; toast popups enabled"
          onActivated: { Settings.doNotDisturb = !Settings.doNotDisturb; Settings.save() }
        }

        ActionButton {
          width: (parent.width - 3 * 8) / 4
          height: width
          iconLabel: "lock"
          labelText: "Lock"
          accessibleName: "Lock screen"
          accessibleDescription: "Locks the session"
          onActivated: {
            root.lockRequested()
            root.dismissed()
          }
        }
      }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)
        }

      Row {
        spacing: 8
        width: parent.width
        layoutDirection: Qt.RightToLeft

        Repeater {
          id: powerRepeater
          model: root.powerOptions

          delegate: ActionButton {
            required property var modelData
            required property int index

            width: (parent.width - 3 * 8) / 4
            height: width
            iconLabel: root.powerIcon(modelData.label)
            labelText: modelData.label
            selected: index === root.activePowerIndex
            accessibleName: modelData.label
            accessibleDescription: "Power action"
            onActiveFocusChanged: {
              if (activeFocus) root.activePowerIndex = index
            }
            onHoveredChanged: {
              if (hovered) root.activePowerIndex = index
            }
            onActivated: {
              root.requestPower(index)
            }
          }
        }
      }
    }
  }

  }
}
