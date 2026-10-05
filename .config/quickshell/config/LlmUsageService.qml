import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root
  required property string providerName
  required property string helperScript

  property var fiveHour: null
  property var weekly: null
  property var resets: null
  property string status: "loading"
  property string statusMessage: "Loading " + root.providerName + " usage…"
  property string resetsMessage: ""
  property string updatedAt: ""
  property bool indicatorActive: false
  property bool popupActive: false
  property double now: Date.now()
  property double lastAttemptAt: 0
  property double retryAt: 0
  readonly property bool rateLimited: retryAt > now
  readonly property string cooldownText: rateLimited
    ? root.resetText(Math.ceil(retryAt / 1000)).replace("Resets in ", "Refresh available in ")
    : ""
  readonly property bool loading: usageProcess.running
  readonly property bool stale: updatedAt !== "" && (status === "error"
    || now - Date.parse(updatedAt) > 10 * 60000)

  onPopupActiveChanged: {
    if (popupActive) refreshIfDue()
  }

  function refreshIfDue() {
    if (Date.now() - root.lastAttemptAt >= 5 * 60000) root.refresh()
  }

  function refresh() {
    root.now = Date.now()
    if (usageProcess.running || root.rateLimited) return
    root.lastAttemptAt = root.now
    usageProcess.running = true
  }

  function resetText(epoch) {
    if (!epoch) return "Reset time unavailable"
    var minutes = Math.ceil((epoch * 1000 - root.now) / 60000)
    if (minutes <= 0) return "Reset due · refresh to update"
    var days = Math.floor(minutes / 1440)
    var hours = Math.floor((minutes % 1440) / 60)
    var rest = minutes % 60
    return "Resets in " + (days > 0 ? days + "d " : "")
      + (hours > 0 ? hours + "h " : "") + rest + "m"
  }

  function expiryText(iso) {
    var time = Date.parse(iso)
    if (!isFinite(time)) return ""
    return "Next expiry: " + Qt.formatDateTime(new Date(time), "MMM d, hh:mm")
  }

  function applyOutput(output) {
    try {
      var info = JSON.parse(output)
      if (info.status !== "ok" && info.status !== "error") throw new Error("Invalid status")
      root.status = info.status
      root.statusMessage = info.message || ""
      var delay = Number(info.retry_after_seconds || 0)
      root.retryAt = isFinite(delay) && delay > 0 ? Date.now() + delay * 1000 : 0
      if (info.status === "ok") {
        root.fiveHour = info.five_hour
        root.weekly = info.weekly
        root.resets = info.resets
        root.resetsMessage = info.resets_message || ""
        root.updatedAt = info.updated_at
      } else {
        // Usage survives transient failures, but reset credits are live-only.
        root.resets = null
        root.resetsMessage = "Available resets require a successful refresh."
      }
    } catch (error) {
      root.status = "error"
      root.statusMessage = root.providerName + " usage helper returned invalid data."
      root.resets = null
      root.resetsMessage = "Available resets require a successful refresh."
    }
    root.now = Date.now()
  }

  property var usageProcess: Process {
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/" + root.helperScript]
    stdout: StdioCollector {
      onStreamFinished: root.applyOutput(text.trim())
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.status = "error"
        root.statusMessage = root.providerName + " usage helper failed (exit " + exitCode + ")."
        root.resets = null
      }
    }
  }

  property var refreshTimer: Timer {
    interval: 5 * 60000
    running: root.indicatorActive || root.popupActive
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshIfDue()
  }

  property var clockTimer: Timer {
    interval: 30000
    running: root.indicatorActive || root.popupActive
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }
}
