local terminal    = "kitty"
local fileManager = "nautilus"
local browser     = "brave-origin"
local quickshellIpc = "quickshell ipc --path \"$HOME/.config/quickshell\" call "

local mainMod     = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

local closeWindowBind = hl.bind(mainMod .. " + W", hl.dsp.window.close())
closeWindowBind:set_enabled(true)

hl.bind(mainMod .. " + M",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))

-- Quickshell binds
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(quickshellIpc .. "bar toggleLauncher"))
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(quickshellIpc .. "session lock"))
-- The former control-center and settings keys share the Quickshell settings surface.
hl.bind("XF86Tools", hl.dsp.exec_cmd(quickshellIpc .. "bar toggleSettings"))
hl.bind("XF86Favorites", hl.dsp.exec_cmd(quickshellIpc .. "bar toggleSettings"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(quickshellIpc .. "bar volumeUp"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(quickshellIpc .. "bar volumeDown"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(quickshellIpc .. "bar toggleMute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(quickshellIpc .. "bar brightnessUp"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(quickshellIpc .. "bar brightnessDown"))
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(quickshellIpc .. "bar keyboardBrightnessUp"))
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(quickshellIpc .. "bar keyboardBrightnessDown"))
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd(quickshellIpc .. "bar keyboardBrightnessToggle"))

-- Screenshots (Quickshell + grim/slurp)
hl.bind("Print", hl.dsp.exec_cmd(quickshellIpc .. "bar screenshotRegion"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd(quickshellIpc .. "bar screenshotFullscreen"))

-- Alt tab (Hyprland owns window focus)
hl.bind("ALT + Tab", hl.dsp.exec_cmd("hyprctl dispatch focuscurrentorlast"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
