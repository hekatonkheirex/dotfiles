.pragma library

// Window switching and layout commands for niri. All actions pass --id so
// they hit the intended window even after the launcher closes.

var LAYOUT = [
  { id: "win-maximize", name: "Maximize window", comment: "Fill the output without hiding bars", icon: "fullscreen", action: ["maximize-window-to-edges"], keywords: "maximize expand edges" },
  { id: "win-fullscreen", name: "Toggle fullscreen", comment: "Fullscreen the focused window", icon: "fullscreen", action: ["fullscreen-window"], keywords: "fullscreen full screen" },
  { id: "win-center", name: "Center window", comment: "Center the focused window", icon: "center_focus_strong", action: ["center-window"], keywords: "center middle" },
  { id: "win-float", name: "Toggle floating", comment: "Float or tile the focused window", icon: "picture_in_picture", action: ["toggle-window-floating"], keywords: "float tile floating tiling" },
  { id: "win-w25", name: "Window width 25%", comment: "", icon: "view_column", action: ["set-window-width", "25%"], keywords: "quarter width" },
  { id: "win-w33", name: "Window width 33%", comment: "One third", icon: "view_column", action: ["set-window-width", "33.333%"], keywords: "third width" },
  { id: "win-w50", name: "Window width 50%", comment: "Left or right half", icon: "view_column", action: ["set-window-width", "50%"], keywords: "half width" },
  { id: "win-w66", name: "Window width 66%", comment: "Two thirds", icon: "view_column", action: ["set-window-width", "66.667%"], keywords: "two thirds width" },
  { id: "win-w75", name: "Window width 75%", comment: "", icon: "view_column", action: ["set-window-width", "75%"], keywords: "three quarters width" },
  { id: "win-w100", name: "Window width 100%", comment: "", icon: "view_column", action: ["set-window-width", "100%"], keywords: "full width" }
]

// `niri msg -j windows` -> [{ id, title, appId, workspaceId, focused }]
function parse(text) {
  try {
    var raw = JSON.parse(text)
    if (!Array.isArray(raw)) return []
    var out = []
    for (var i = 0; i < raw.length; i++) {
      var w = raw[i]
      if (!w || typeof w.id !== "number") continue
      out.push({
        id: w.id,
        title: typeof w.title === "string" ? w.title : "",
        appId: typeof w.app_id === "string" ? w.app_id : "",
        workspaceId: typeof w.workspace_id === "number" ? w.workspace_id : null,
        focused: w.is_focused === true
      })
    }
    return out
  } catch (e) {
    return []
  }
}

function niri(action, id) {
  var argv = ["niri", "msg", "action", action[0]]
  if (id !== null && id !== undefined) argv.push("--id", String(id))
  return argv.concat(action.slice(1))
}

function layoutArgv(cmd, focusedId) { return niri(cmd.action, focusedId) }

function focusArgv(id) { return niri(["focus-window"], id) }
function closeArgv(id) { return niri(["close-window"], id) }

function toItems(windows, appNames) {
  return windows.map(function(w) {
    var app = (appNames && appNames[w.appId.toLowerCase()]) || w.appId || "Window"
    return {
      id: "win:" + w.id, kind: "window", name: w.title || app, comment: app,
      keywords: "window switch focus " + w.appId, icon: "web_asset", tag: "Window",
      payload: { windowId: w.id, focusArgv: focusArgv(w.id), closeArgv: closeArgv(w.id) }
    }
  })
}

function layoutItems(focusedId) {
  if (focusedId === null || focusedId === undefined) return []
  return LAYOUT.map(function(c) {
    return {
      id: c.id, kind: "command", name: c.name, comment: c.comment, keywords: "window " + c.keywords,
      icon: c.icon, tag: "Window", payload: { argv: layoutArgv(c, focusedId) }
    }
  })
}
