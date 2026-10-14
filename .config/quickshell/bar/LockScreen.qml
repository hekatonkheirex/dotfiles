import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "powermenu"
import "../config"

Item {
  id: root

  property bool locked: false
  // Quickshell 0.3.2 can omit lockedChanged on unlock. Read secure first so
  // its notification invalidates this binding and lets the bar map again.
  readonly property bool compositorLocked: Config.isNiri && sessionLock.secure && sessionLock.locked
  // Keep secure first here too: locked can also miss its start notification.
  readonly property bool secure: Config.isNiri && sessionLock.secure && sessionLock.locked
  onLockedChanged: {
    updateReloadWatchState()
    if (locked) {
      fprintdProcess.running = true
    } else {
      fprintdProcess.running = false
      fprintdRetry.stop()
    }
  }

  property string lockPassword: ""
  property string lockInputText: ""
  property string lockError: ""
  property bool authenticated: false

  function username() {
    return Quickshell.env("USER") || "user"
  }

  function updateReloadWatchState() {
    // Destroying a WlSessionLock while it is active leaves the compositor in
    // its secure fallback state. Do not let a file change start a reload in
    // that window; unlock restores the normal watcher behavior.
    Quickshell.watchFiles = !(root.locked || sessionLock.locked)
  }

  function clearPassword() {
    lockPassword = ""
    lockInputText = ""
    lockPam.pendingPassword = ""
  }

  function lockScreen() {
    clearPassword()
    lockError = ""
    authenticated = false

    // Mango's layer-shell fallback is only a visual overlay, not a Wayland
    // session lock. Use the standalone locker there so compositor shortcuts
    // cannot bypass authentication.
    if (!Config.isNiri) {
      Quickshell.execDetached(["swaylock", "-f"])
      return
    }

    root.locked = true
    updateReloadWatchState()
    sessionLock.locked = true
  }

  function unlockSession() {
    authenticated = true
    clearPassword()
    root.locked = false
    if (Config.isNiri) sessionLock.locked = false
    updateReloadWatchState()
    Quickshell.execDetached(["loginctl", "unlock-session"])
  }

  function tryLockAuth() {
    if (lockPassword.length === 0) return
    lockPam.user = root.username()
    lockPam.pendingPassword = lockPassword
    lockError = ""
    lockPam.start()
  }

  PamContext {
    id: lockPam
    property string pendingPassword: ""

    config: "system-auth"

    onResponseRequiredChanged: {
      if (responseRequired && pendingPassword !== "") {
        respond(pendingPassword)
        pendingPassword = ""
      }
    }

    onCompleted: (result) => {
      if (result === PamResult.Success) {
        root.unlockSession()
      } else {
        root.clearPassword()
        root.lockError = "Wrong password. Try again."
      }
    }
    onError: (error) => {
      root.clearPassword()
      root.lockError = "Authentication error. Try again."
    }
  }

  Process {
    id: fprintdProcess
    command: ["fprintd-verify", root.username()]
    running: false

    property var startTime: 0

    onRunningChanged: {
      if (running) {
        startTime = Date.now()
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root.locked && !root.authenticated) {
        root.unlockSession()
      } else if (root.locked && !root.authenticated) {
        var elapsed = Date.now() - startTime
        if (elapsed < 1500) {
          // If the process exited very quickly, the device might be busy,
          // unplugged, or recovering from sleep. Use a 5s cooldown.
          fprintdRetry.interval = 5000
        } else {
          // Normal retry (e.g. wrong finger scanned).
          fprintdRetry.interval = 2000
        }
        fprintdRetry.start()
      }
    }
  }

  Timer {
    id: fprintdRetry
    interval: 2000
    onTriggered: {
      if (root.locked && !root.authenticated) {
        fprintdProcess.running = true
      }
    }
  }


  WlSessionLock {
    id: sessionLock
    // Keep the local mirror synchronized with compositor-owned state before
    // the bar evaluates its visibility binding. Active lock reloads are
    // blocked above because destroying WlSessionLock while locked violates
    // the Wayland session-lock protocol.
    Component.onCompleted: {
      if (Config.isNiri) root.locked = sessionLock.locked
      root.updateReloadWatchState()
    }
    onLockedChanged: {
      if (!Config.isNiri) return
      if (locked) {
        root.lockPassword = ""
        root.lockInputText = ""
        root.lockError = ""
        root.authenticated = false
      }
      root.locked = locked
    }
    surface: Component {
      WlSessionLockSurface {
        color: Colors.surface

        LockSurfaceContent {
          anchors.fill: parent
          password: root.lockInputText
          authFailed: root.lockError !== ""
          onEdited: {
            root.lockPassword = typed
            root.lockInputText = typed
            root.lockError = ""
          }
          onSubmitted: root.tryLockAuth()
        }
      }
    }
  }

  Loader {
    active: !Config.isNiri && root.locked
    sourceComponent: PanelWindow {
      color: Colors.surface
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-lock"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.focusable: true
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      anchors.left: true
      anchors.right: true
      anchors.top: true
      anchors.bottom: true

      LockSurfaceContent {
        anchors.fill: parent
        password: root.lockInputText
        authFailed: root.lockError !== ""
        onEdited: {
          root.lockPassword = typed
          root.lockInputText = typed
          root.lockError = ""
        }
        onSubmitted: root.tryLockAuth()
      }
    }
  }
}
