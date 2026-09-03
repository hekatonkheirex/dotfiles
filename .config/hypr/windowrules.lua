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
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true, default_name = "code" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true, default_name = "file" })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true, default_name = "chat" })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true, default_name = "record" })

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

-- Noctalia Settings
hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})

hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
