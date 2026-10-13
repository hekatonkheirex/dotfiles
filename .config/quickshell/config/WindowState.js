.pragma library

// Folds niri event-stream events into the little the dock needs. Pure: never
// mutates its input, and returns the SAME object when an event changes nothing
// the dock shows (niri emits WindowOpenedOrChanged on every title change).

function empty() {
  return { windows: [], focusedWindowId: null, focusedWorkspaceId: null, clock: 0 }
}

function tsOf(stamp) {
  return stamp && typeof stamp.secs === "number" ? stamp.secs * 1e9 + (stamp.nanos || 0) : 0
}

function compact(w) {
  return {
    id: w.id,
    appId: typeof w.app_id === "string" ? w.app_id : "",
    workspaceId: typeof w.workspace_id === "number" ? w.workspace_id : null,
    focused: !!w.is_focused,
    urgent: !!w.is_urgent,
    focusTs: tsOf(w.focus_timestamp)
  }
}

function sameWindow(a, b) {
  return a.id === b.id && a.appId === b.appId && a.workspaceId === b.workspaceId
    && a.focused === b.focused && a.urgent === b.urgent && a.focusTs === b.focusTs
}

function indexOfId(windows, id) {
  for (var i = 0; i < windows.length; i++) if (windows[i].id === id) return i
  return -1
}

function make(windows, focusedWindowId, focusedWorkspaceId, clock) {
  return { windows: windows, focusedWindowId: focusedWindowId, focusedWorkspaceId: focusedWorkspaceId, clock: clock }
}

function copyWith(w, patch) {
  var out = {}
  for (var k in w) out[k] = w[k]
  for (var p in patch) out[p] = patch[p]
  return out
}

function applyEvent(state, event) {
  if (!event || typeof event !== "object") return state
  var keys = Object.keys(event)
  if (keys.length === 0) return state
  var kind = keys[0]
  var p = event[kind]
  var i, windows

  if (kind === "WindowsChanged") {
    var list = p && Array.isArray(p.windows) ? p.windows : []
    var compacted = []
    var focused = null
    var clock = state.clock
    for (i = 0; i < list.length; i++) {
      if (!list[i] || typeof list[i].id !== "number") continue
      var c = compact(list[i])
      if (c.focused) focused = c.id
      if (c.focusTs > clock) clock = c.focusTs
      compacted.push(c)
    }
    return make(compacted, focused, state.focusedWorkspaceId, clock)
  }

  if (kind === "WindowOpenedOrChanged") {
    if (!p || !p.window || typeof p.window.id !== "number") return state
    var w = compact(p.window)
    var at = indexOfId(state.windows, w.id)
    if (at >= 0 && sameWindow(state.windows[at], w)
        && (!w.focused || state.focusedWindowId === w.id)) return state
    windows = state.windows.slice()
    if (at >= 0) windows[at] = w
    else windows.push(w)
    var focusedId = state.focusedWindowId
    if (w.focused) {
      focusedId = w.id
      for (i = 0; i < windows.length; i++) {
        if (windows[i].id !== w.id && windows[i].focused) windows[i] = copyWith(windows[i], { focused: false })
      }
    } else if (focusedId === w.id) {
      focusedId = null
    }
    return make(windows, focusedId, state.focusedWorkspaceId, Math.max(state.clock, w.focusTs))
  }

  if (kind === "WindowClosed") {
    if (!p || typeof p.id !== "number") return state
    var gone = indexOfId(state.windows, p.id)
    if (gone < 0) return state
    windows = state.windows.slice()
    windows.splice(gone, 1)
    return make(windows, state.focusedWindowId === p.id ? null : state.focusedWindowId,
                state.focusedWorkspaceId, state.clock)
  }

  if (kind === "WindowFocusChanged") {
    var id = p && typeof p.id === "number" ? p.id : null
    if (id === state.focusedWindowId) return state
    var tick = state.clock + 1
    windows = []
    for (i = 0; i < state.windows.length; i++) {
      var cur = state.windows[i]
      if (cur.id === id) windows.push(copyWith(cur, { focused: true, focusTs: tick }))
      else if (cur.focused) windows.push(copyWith(cur, { focused: false }))
      else windows.push(cur)
    }
    return make(windows, id, state.focusedWorkspaceId, id === null ? state.clock : tick)
  }

  if (kind === "WindowUrgencyChanged") {
    if (!p || typeof p.id !== "number") return state
    var u = indexOfId(state.windows, p.id)
    if (u < 0 || state.windows[u].urgent === !!p.urgent) return state
    windows = state.windows.slice()
    windows[u] = copyWith(windows[u], { urgent: !!p.urgent })
    return make(windows, state.focusedWindowId, state.focusedWorkspaceId, state.clock)
  }

  if (kind === "WorkspacesChanged") {
    var rows = p && Array.isArray(p.workspaces) ? p.workspaces : []
    var fw = null
    for (i = 0; i < rows.length; i++) if (rows[i] && rows[i].is_focused) fw = rows[i].id
    if (fw === null || fw === state.focusedWorkspaceId) return state
    return make(state.windows, state.focusedWindowId, fw, state.clock)
  }

  if (kind === "WorkspaceActivated") {
    if (!p || !p.focused || typeof p.id !== "number" || p.id === state.focusedWorkspaceId) return state
    return make(state.windows, state.focusedWindowId, p.id, state.clock)
  }

  return state
}

// True when the focused workspace is known and holds no windows.
function workspaceEmpty(state) {
  if (!state || state.focusedWorkspaceId === null) return false
  for (var i = 0; i < state.windows.length; i++) {
    if (state.windows[i].workspaceId === state.focusedWorkspaceId) return false
  }
  return true
}
