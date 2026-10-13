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
  signal settingsRequested()

  readonly property int lockPowerIndex: root.powerOptions.length
  readonly property int settingsPowerIndex: root.lockPowerIndex + 1

  property bool caffeineOn: false
  property bool airplaneOn: false
  property bool bluetoothOn: false

  readonly property int actionGap: (Config.spacingSmall)
  // The hint reads live state. Storing the formatted string at hover time
  // left it stale when the async state probes finished after the popup opened.
  property string controlHintKey: ""
  readonly property string controlHint: {
    var k = root.controlHintKey
    if (k === "") return ""
    var on = k === "Caffeine" ? root.caffeineOn
      : (k === "Airplane mode" ? root.airplaneOn
        : (k === "Bluetooth" ? root.bluetoothOn
          : (k === "Do Not Disturb" ? Settings.doNotDisturb : null)))
    return k + (on === null ? "" : (on ? " · On" : " · Off"))
  }

  function showControlHint(label, enabled, active) {
    if (active) root.controlHintKey = label
    else if (root.controlHintKey === label) root.controlHintKey = ""
  }
  Process {
    id: idleCheck
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh", "status"]
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

  Process {
    id: bluetoothCheck
    command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.bluetoothOn = text.trim() === "on"
    }
  }

  function toggleCaffeine() {
    if (root.caffeineOn) {
      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
      root.caffeineOn = false
    } else {
      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh", "stop"])
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
    root.bluetoothOn = !newState
  }

  function toggleBluetooth() {
    var newState = !root.bluetoothOn
    Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"])
    root.bluetoothOn = newState
  }

  function focusPower(index) {
    root.activePowerIndex = index
    var item = index === root.lockPowerIndex ? lockPowerButton
      : (index === root.settingsPowerIndex ? settingsPowerButton : powerRepeater.itemAt(index))
    if (item) item.forceActiveFocus()
  }

  function requestLock() {
    root.lockRequested()
    root.dismissed()
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


  implicitWidth: Config.popupWidth
  visible: false
  implicitHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("popup")
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: Config.barWidth + Config.spacingCompact
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  Process {
    id: focusedWindowQuery
    command: Config.isMango
      ? ["mmsg", "get", "focusing-client"]
      : ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg -j focused-window"]
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
      if (root.visible && (Config.isNiri || Config.isMango) && !focusedWindowQuery.running) {
        focusedWindowQuery.running = true
      }
    }
  }

  Timer {
    id: focusDismissArmTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (!root.visible || (!Config.isNiri && !Config.isMango)) return
      root.focusDismissArmed = true
      root.focusWindowBaselineReady = false
      if (!focusedWindowQuery.running) focusedWindowQuery.running = true
    }
  }

  Process {
    id: focusEventWatcher
    command: Config.isMango
      ? ["mmsg", "watch", "focusing-client"]
      : ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg event-stream"]
    running: root.visible && (Config.isNiri || Config.isMango)

    stdout: SplitParser {
      onRead: function(data) {
        if (root.visible && root.focusWindowBaselineReady) focusQueryDebounce.restart()
      }
    }

    onRunningChanged: {
      if (!running && root.visible && (Config.isNiri || Config.isMango)) focusEventWatcherRetry.start()
    }
  }

  Timer {
    id: focusEventWatcherRetry
    interval: 1000
    repeat: false
    onTriggered: {
      if (root.visible && (Config.isNiri || Config.isMango)) focusEventWatcher.running = true
    }
  }

  onVisibleChanged: {
    focusQueryDebounce.stop()
    focusEventWatcherRetry.stop()
    focusDismissArmTimer.stop()
    if (visible) {
      if (Config.reducedMotion) {
        entryAnimation.stop()
        reducedMotionEntryAnimation.stop()
        scaleTransform.xScale = 1.0
        scaleTransform.yScale = 1.0
        transX.x = 0
        {
          bg.opacity = 1.0
        }
      } else {
        entryAnimation.start()
      }
      root.controlHintKey = ""
      root.activePowerIndex = -1
      root.pendingPowerIndex = -1
      root.focusWindowId = ""
      root.focusWindowBaselineReady = false
      root.focusDismissArmed = false
      mainItem.forceActiveFocus()
      root.openTime = Date.now()
      idleCheck.running = true
      airplaneCheck.running = true
      bluetoothCheck.running = true
      if (Config.isNiri || Config.isMango) {
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
      } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
          || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
        var len = root.powerOptions.length + 2
        var delta = event.key === Qt.Key_Left ? -1 : (event.key === Qt.Key_Right ? 1 : 3)
        var nextIndex = root.activePowerIndex < 0 ? 0 : (root.activePowerIndex + delta + len) % len
        root.focusPower(nextIndex)
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (root.activePowerIndex === root.lockPowerIndex) {
          root.requestLock()
          event.accepted = true
        } else if (root.activePowerIndex === root.settingsPowerIndex) {
          root.settingsRequested()
          event.accepted = true
        } else if (root.activePowerIndex >= 0 && root.activePowerIndex < root.powerOptions.length) {
          root.requestPower(root.activePowerIndex)
          event.accepted = true
        }
      }
    }


    Rectangle {
      id: bg
      anchors.fill: parent
      radius: Config.popupRadius
      color: Colors.surface
      clip: true
      DashedFrame { anchors.fill: parent; active: root.visible; radius: bg.radius }


      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

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

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: Config.popupPadding
        }
        spacing: (Config.spacingMedium)

        Text {
          text: "/ SESSION /"
          color: Colors.primary
          font.family: "monospace"
          font.pixelSize: Config.typeTitleMediumSize
          font.letterSpacing: Config.typeMonoTracking
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
        }

        Row {
          width: parent.width
          spacing: Config.spacingSmall

          Text {
            text: "CONTROLS"
            color: Colors.fgSurfaceVariant
            font.family: "monospace"
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeMonoTracking
          }

          Text {
            width: parent.width - x
            text: root.controlHint
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelMediumSize
          }
        }

      Row {
        spacing: root.actionGap
        width: parent.width

        ActionButton {
          width: (parent.width - 3 * root.actionGap) / 4
          height: width
          iconLabel: "coffee"
          labelText: ""
          tooltipText: "Caffeine mode"
          selected: root.caffeineOn
          checkable: true
          horizontalContent: false
          accessibleName: "Caffeine mode"
          accessibleDescription: root.caffeineOn ? "Enabled" : "Disabled"
          onHoveredChanged: root.showControlHint("Caffeine", root.caffeineOn, hovered || activeFocus)
          onActiveFocusChanged: root.showControlHint("Caffeine", root.caffeineOn, hovered || activeFocus)
          onActivated: {
            root.toggleCaffeine()
            root.showControlHint("Caffeine", root.caffeineOn, hovered || activeFocus)
          }
        }

        ActionButton {
          width: (parent.width - 3 * root.actionGap) / 4
          height: width
          iconLabel: root.airplaneOn ? "airplanemode_active" : "airplanemode_inactive"
          labelText: ""
          tooltipText: "Airplane mode"
          selected: root.airplaneOn
          checkable: true
          horizontalContent: false
          accessibleName: "Airplane mode"
          accessibleDescription: root.airplaneOn ? "Enabled" : "Disabled"
          onHoveredChanged: root.showControlHint("Airplane mode", root.airplaneOn, hovered || activeFocus)
          onActiveFocusChanged: root.showControlHint("Airplane mode", root.airplaneOn, hovered || activeFocus)
          onActivated: {
            root.toggleAirplane()
            root.showControlHint("Airplane mode", root.airplaneOn, hovered || activeFocus)
          }
        }

        ActionButton {
          width: (parent.width - 3 * root.actionGap) / 4
          height: width
          iconLabel: root.bluetoothOn ? "bluetooth_connected" : "bluetooth_disabled"
          labelText: ""
          tooltipText: "Bluetooth"
          selected: root.bluetoothOn
          checkable: true
          horizontalContent: false
          accessibleName: "Bluetooth"
          accessibleDescription: root.bluetoothOn ? "Enabled" : "Disabled"
          onHoveredChanged: root.showControlHint("Bluetooth", root.bluetoothOn, hovered || activeFocus)
          onActiveFocusChanged: root.showControlHint("Bluetooth", root.bluetoothOn, hovered || activeFocus)
          onActivated: {
            root.toggleBluetooth()
            root.showControlHint("Bluetooth", root.bluetoothOn, hovered || activeFocus)
          }
        }

        ActionButton {
          width: (parent.width - 3 * root.actionGap) / 4
          height: width
          iconLabel: "do_not_disturb_on"
          labelText: ""
          tooltipText: "Do Not Disturb"
          selected: Settings.doNotDisturb
          checkable: true
          horizontalContent: false
          accessibleName: "Do Not Disturb"
          accessibleDescription: Settings.doNotDisturb
            ? "Enabled; toast popups suppressed and history retained"
            : "Disabled; toast popups enabled"
          onHoveredChanged: root.showControlHint("Do Not Disturb", Settings.doNotDisturb, hovered || activeFocus)
          onActiveFocusChanged: root.showControlHint("Do Not Disturb", Settings.doNotDisturb, hovered || activeFocus)
          onActivated: {
            Settings.doNotDisturb = !Settings.doNotDisturb
            Settings.save()
            root.showControlHint("Do Not Disturb", Settings.doNotDisturb, hovered || activeFocus)
          }
        }

      }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
        }

        Row {
          width: parent.width
          spacing: Config.spacingSmall

          Text {
            text: "SESSION ACTIONS"
            color: Colors.fgSurfaceVariant
            font.family: "monospace"
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeMonoTracking
          }

          Text {
            width: parent.width - x
            text: root.activePowerIndex < 0 ? ""
              : (root.activePowerIndex === root.lockPowerIndex ? "Lock screen"
                : (root.activePowerIndex === root.settingsPowerIndex ? "Settings"
                  : root.powerOptions[root.activePowerIndex].label))
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelMediumSize
          }
        }

      Grid {
        spacing: root.actionGap
        width: parent.width
        columns: 3

        Repeater {
          id: powerRepeater
          model: root.powerOptions

          delegate: ActionButton {
            required property var modelData
            required property int index

            width: (parent.width - 2 * root.actionGap) / 3
            height: Math.max(80, Config.controlHitSize)
            iconLabel: root.powerIcon(modelData.label)
            labelText: modelData.label
            selected: index === root.activePowerIndex
            horizontalContent: false
            tooltipText: modelData.label
            accessibleName: modelData.label
            accessibleDescription: root.powerDescription(modelData.label)
            onActiveFocusChanged: {
              if (activeFocus) root.activePowerIndex = index
              else if (!hovered && root.activePowerIndex === index) root.activePowerIndex = -1
            }
            onHoveredChanged: {
              if (hovered) root.activePowerIndex = index
              else if (!activeFocus && root.activePowerIndex === index) root.activePowerIndex = -1
            }
            onActivated: {
              root.requestPower(index)
            }
          }
        }

        ActionButton {
          id: lockPowerButton
          width: (parent.width - 2 * root.actionGap) / 3
          height: Math.max(80, Config.controlHitSize)
          iconLabel: "lock"
          labelText: "Lock"
          selected: root.activePowerIndex === root.lockPowerIndex
          horizontalContent: false
          tooltipText: "Lock screen"
          accessibleName: "Lock screen"
          accessibleDescription: "Locks the session"
          onActiveFocusChanged: {
            if (activeFocus) root.activePowerIndex = root.lockPowerIndex
            else if (!hovered && root.activePowerIndex === root.lockPowerIndex) root.activePowerIndex = -1
          }
          onHoveredChanged: {
            if (hovered) root.activePowerIndex = root.lockPowerIndex
            else if (!activeFocus && root.activePowerIndex === root.lockPowerIndex) root.activePowerIndex = -1
          }
          onActivated: root.requestLock()
        }

        ActionButton {
          id: settingsPowerButton
          width: (parent.width - 2 * root.actionGap) / 3
          height: Math.max(80, Config.controlHitSize)
          iconLabel: "settings"
          labelText: "Settings"
          horizontalContent: false
          selected: root.activePowerIndex === root.settingsPowerIndex
          accessibleName: "Settings"
          accessibleDescription: "Opens shell settings"
          tooltipText: accessibleName
          onActiveFocusChanged: {
            if (activeFocus) root.activePowerIndex = root.settingsPowerIndex
            else if (!hovered && root.activePowerIndex === root.settingsPowerIndex) root.activePowerIndex = -1
          }
          onHoveredChanged: {
            if (hovered) root.activePowerIndex = root.settingsPowerIndex
            else if (!activeFocus && root.activePowerIndex === root.settingsPowerIndex) root.activePowerIndex = -1
          }
          onActivated: root.settingsRequested()
        }
      }

      Text {
        width: parent.width
        text: "ARROWS SELECT · ENTER CHOOSE · ESC CLOSE"
        color: Colors.fgSurfaceVariant
        font.family: "monospace"
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeMonoTracking
        wrapMode: Text.Wrap
      }
    }
  }

  }
}
