.pragma library

// Ctrl+K action panel: the actions offered for a result, first one is the
// default (Enter). id strings are handled by LauncherPopup.runPanelAction.

function actionsFor(item, opts) {
  if (!item) return []
  var o = opts || {}
  switch (item.kind) {
    case "app": {
      var a = [{ id: "open", label: "Open application" }]
      if (!item.terminal) a.push({ id: "open-terminal", label: "Run in terminal" })
      a.push({ id: "copy-command", label: "Copy launch command" })
      return a
    }
    case "calc":
      return [{ id: "copy", label: "Copy result" }, { id: "copy-expression", label: "Copy expression and result" }]
    case "quicklink":
      return [{ id: "open-url", label: "Open link" }, { id: "copy-url", label: "Copy URL" }]
    case "snippet":
    case "emoji": {
      var s = [{ id: "copy", label: "Copy to clipboard" }]
      if (o.canType) s.push({ id: "paste", label: "Paste into focused window" })
      return s
    }
    case "window":
      return [{ id: "focus-window", label: "Switch to window" }, { id: "close-window", label: "Close window", destructive: true }]
    case "clipboard":
      return [{ id: "restore", label: "Restore clipboard entry" }, { id: "delete-clipboard", label: "Delete clipboard entry", destructive: true }]
    case "clipboard-action":
      return [{ id: "run-action", label: item.name }]
    case "command":
      return [{ id: "run-command", label: "Run command" }]
    case "action":
      return [{ id: "run-action", label: "Run action" }]
    default:
      return []
  }
}
