local suppressMaximizeRule = hl.window_rule({
  -- Ignore maximize requests from all apps. You'll probably like this.
  name           = "suppress-maximize-events",
  match          = { class = ".*" },

  suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- Persistent Workspaces
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", persistent = true, default_name = "web" })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true, default_name = "term" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true, default_name = "file" })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true, default_name = "code" })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true, default_name = "rec" })

-- Smart Gaps
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" }, rounding = 0 })

-- Window Rules
hl.window_rule({
  name = "brave-origin",
  match = { class = "brave-origin" },
  workspace = 1
})

hl.window_rule({
  name = "kitty",
  match = { class = "kitty" },
  workspace = 2
})

hl.window_rule({
  name = "file-manager",
  match = { class = "org.gnome.Nautilus" },
  workspace = 3
})

-- Quickshell popup motion is handled by PopupMotion.qml.
hl.layer_rule({
  name = "quickshell-popup",
  match = { namespace = "^quickshell-hyprland-popup-.+$" },
  no_anim = true,
})

hl.layer_rule({
  name = "quickshell-settings",
  match = { namespace = "^quickshell-hyprland-settings$" },
  no_anim = true,
})
