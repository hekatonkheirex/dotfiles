// Gate test: node tests/power-menu/lock-wiring.test.mjs
// The lock surface takes her look; PAM, WlSessionLock and the reload guard
// must stay byte-for-byte as they were at 0e166e49. The verbatim blocks below
// are copied from that commit.
import { existsSync, readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const lock = rd(process.env.LOCKSCREEN_QML || "../../bar/LockScreen.qml")
const has = (block, what) => assert.ok(lock.includes(block), "LockScreen.qml keeps " + what + " verbatim")

// --- Pinned: secure-lock state, PAM, fingerprint, session lock ---
has(`  readonly property bool compositorLocked: Config.isNiri && sessionLock.secure && sessionLock.locked
`, "compositorLocked")
has(`  readonly property bool secure: Config.isNiri && sessionLock.secure && sessionLock.locked
`, "secure")
assert.match(lock, /  onLockedChanged: \{\n    updateReloadWatchState\(\)\n    if \(locked\) \{\n      fprintdProcess\.running = true\n(      currentWallpaperProc\.running = root\.wallpaperRequested\n)?    \} else \{\n      fprintdProcess\.running = false\n      fprintdRetry\.stop\(\)\n(      currentWallpaperProc\.running = root\.wallpaperRequested\n)?    \}\n  \}/,
  "root onLockedChanged keeps the reload guard and fingerprint start/stop")
has(`  property string lockPassword: ""
  property string lockInputText: ""
  property string lockError: ""
  property bool authenticated: false
`, "auth state")
has(`  function username() {
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
`, "username/updateReloadWatchState/clearPassword")
// lockScreen(): only the call into the removed power-confirmation state may go.
assert.match(lock, /  function lockScreen\(\) \{\n    clearPassword\(\)\n    lockError = ""\n    authenticated = false\n(    cancelPowerAction\(\)\n)?\n    \/\/ Mango's layer-shell fallback is only a visual overlay, not a Wayland\n    \/\/ session lock\. Use the standalone locker there so compositor shortcuts\n    \/\/ cannot bypass authentication\.\n    if \(!Config\.isNiri\) \{\n      Quickshell\.execDetached\(\["swaylock", "-f"\]\)\n      return\n    \}\n\n    root\.locked = true\n    updateReloadWatchState\(\)\n    sessionLock\.locked = true\n  \}/,
  "lockScreen() order: clear, swaylock on non-niri, then lock")
has(`  function unlockSession() {
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
`, "unlockSession/tryLockAuth")
has(`  PamContext {
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
`, "PamContext and fprintd process head")
has(`    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root.locked && !root.authenticated) {
        root.unlockSession()
      } else if (root.locked && !root.authenticated) {`, "fprintd success path")
has(`  WlSessionLock {
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
      }`, "WlSessionLock head and locked reset")
// After the locked branch: only the removed power-confirmation reset may differ.
assert.match(lock, /        root\.authenticated = false\n      \}( else \{\n        root\.cancelPowerAction\(\)\n      \})?\n      root\.locked = locked\n    \}\n    surface: Component \{\n      WlSessionLockSurface \{/,
  "sessionLock mirrors locked, then the surface is a WlSessionLockSurface")
has(`  Loader {
    active: !Config.isNiri && root.locked
    sourceComponent: PanelWindow {`, "fallback loader gate")
has(`      WlrLayershell.namespace: "quickshell-lock"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.focusable: true
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      anchors.left: true
      anchors.right: true
      anchors.top: true
      anchors.bottom: true
`, "fallback layer contract")
assert.equal((lock.match(/Config\.isNiri\) root\.locked = sessionLock\.locked/g) || []).length, 1)
assert.equal((lock.match(/lockPam\.start\(\)/g) || []).length, 1, "one PAM start")
assert.equal((lock.match(/root\.unlockSession\(\)/g) || []).length, 2, "unlock only from PAM success and fprintd")
console.log("lock-wiring pins ok")

// --- Task 4: her look, old lock furniture gone ---
for (const gone of ["Settings.lockShowMedia", "Settings.lockClockSize", "Settings.lockUseWallpaper",
  "lockMprisProcess", "MultiEffect", "profile.jpg", "requestPowerAction", "cancelPowerAction",
  "confirmPowerAction", "pendingPower", "PowerConfirmation", "currentWallpaperProc", "AnimatedBackground",
  "IconButton", "QtQuick.Effects"])
  assert.ok(!lock.includes(gone), "LockScreen.qml no longer has " + gone)
// Both surfaces host the shared content and wire it to the auth state.
const native = lock.slice(lock.indexOf("WlSessionLockSurface {"), lock.indexOf("  Loader {"))
const fallback = lock.slice(lock.indexOf("  Loader {"))
for (const [name, s] of [["session-lock surface", native], ["fallback surface", fallback]]) {
  assert.match(s, /LockSurfaceContent \{/, name + " uses LockSurfaceContent")
  assert.match(s, /anchors\.fill: parent/, name + " fills the surface")
  assert.match(s, /authFailed: root\.lockError !== ""/, name + " shows failed auth")
  assert.match(s, /onSubmitted: root\.tryLockAuth\(\)/, name + " submits through tryLockAuth")
  assert.match(s, /root\.lockPassword = typed/, name + " feeds lockPassword")
  assert.match(s, /root\.lockInputText = typed/, name + " feeds lockInputText")
  assert.match(s, /root\.lockError = ""/, name + " clears the error on edit")
  assert.match(s, /password: root\.lockInputText/, name + " follows lockInputText (cleared after PAM)")
}
assert.match(lock, /import "powermenu"/)
// Both surface bodies, verbatim to the end of the file: nothing else may
// touch auth state, the surface color or the content's visibility.
assert.ok(lock.endsWith(`    surface: Component {
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
`), "both lock surface bodies are pinned verbatim")

const content = rd(process.env.LOCKSURFACE_QML || "../../bar/powermenu/LockSurfaceContent.qml")
assert.match(content, /property string password/)
assert.match(content, /property bool authFailed/)
assert.match(content, /signal submitted\(\)/)
assert.match(content, /signal edited\(string action\)/)
assert.match(content, /echoMode: TextInput\.Password/)
assert.match(content, /forceActiveFocus\(\)/)
assert.match(content, /function focusInput\(\) \{ input\.forceActiveFocus\(\) \}/)
assert.match(content, /Component\.onCompleted: \{ root\.shown = true; root\.focusInput\(\) \}/, "focus on map")
assert.match(content, /onVisibleChanged: if \(visible\) root\.focusInput\(\)/, "focus when shown again")
assert.match(content, /    id: input\n    objectName: "lockInput"\n    width: 1\n    height: 1\n    opacity: 0\n    focus: true\n/, "input declares focus")
assert.match(content, /onPressed: root\.focusInput\(\)/, "any press refocuses")
assert.match(content, /Key_Return \|\| event\.key === Qt\.Key_Enter\) \{\s*root\.submitted\(\)/)
assert.match(content, /PowerMenuContent \{[\s\S]*locked: true/)
assert.match(content, /inputLength: input\.text\.length/)
assert.match(content, /authFailed: root\.authFailed/)
assert.match(content, /color: Colors\.surface\b/)
assert.match(content, /duration: Config\.reducedMotion \? 0 : 1200/)
assert.doesNotMatch(content, /\bcomponent \w+:/, "no inline components")

// --- Settings: the lock look settings are gone and stay loadable as legacy ---
const settings = rd("../../config/Settings.qml")
const legacy = JSON.parse(rd("../elena/config-dump.legacy.json"))
for (const k of ["lockShowSeconds", "lockFontSize", "lockClockSize", "lockShowMedia", "lockUseWallpaper"]) {
  assert.ok(!new RegExp(`\\b${k}\\b`).test(settings), "Settings.qml drops " + k)
  assert.ok(k in legacy, "config-dump legacy fixture lists " + k)
}
const panel = rd("../../bar/SettingsPanel.qml")
const lockTab = rd("../../bar/settings/LockMediaTab.qml")
assert.doesNotMatch(panel, /title: "Show now playing"|title: "Use current wallpaper"/)
assert.doesNotMatch(lockTab, /Settings\.lock(ShowMedia|UseWallpaper|ClockSize)/)
assert.ok(!existsSync(fileURLToPath(new URL("../../bar/QuickMenu.qml", import.meta.url))))
console.log("lock-wiring ok")
