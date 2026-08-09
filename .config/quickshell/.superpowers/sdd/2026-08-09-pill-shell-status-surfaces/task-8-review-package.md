## Commits
2b41cfc8 Add niri keybinds for battery, brightness, wifi, bluetooth pill surfaces

## Diffstat
 .config/niri/keybinds.kdl | 7 +++++++
 1 file changed, 7 insertions(+)

## Full diff
diff --git a/.config/niri/keybinds.kdl b/.config/niri/keybinds.kdl
index dacca73b..c558ec84 100644
--- a/.config/niri/keybinds.kdl
+++ b/.config/niri/keybinds.kdl
@@ -9,20 +9,27 @@ binds {
   Mod+B hotkey-overlay-title="Open Web Browser: Brave Browser" { spawn "brave-origin"; }
   Mod+T hotkey-overlay-title="Open File Manager: Nautilus" { spawn "nautilus"; }
   Mod+Escape repeat=false hotkey-overlay-title="Open Quick Settings" { spawn "~/.config/quickshell/scripts/quickmenu"; }
   Mod+A hotkey-overlay-title="Open OpenCode" { spawn "kitty" "-e" "opencode"; }
 
   // Pill shell (Quickshell -p pill): mixer surface toggle/hide.
   // Mod+Escape is already bound above (Open Quick Settings), so hide uses Mod+Shift+Escape.
   Mod+M hotkey-overlay-title="Open Pill Mixer" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "mixer" ""; }
   Mod+Shift+Escape repeat=false hotkey-overlay-title="Hide Pill Mixer" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "hide"; }
 
+  // Pill shell (Quickshell -p pill): battery/brightness/wifi/bluetooth surfaces.
+  // Mod+Shift+U collides with move-workspace-down (below), so bluetooth uses Mod+Shift+T instead.
+  Mod+Shift+B hotkey-overlay-title="Open Pill Battery" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "battery" ""; }
+  Mod+Shift+N hotkey-overlay-title="Open Pill Brightness" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "brightness" ""; }
+  Mod+Shift+W hotkey-overlay-title="Open Pill Wifi" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "wifi" ""; }
+  Mod+Shift+T hotkey-overlay-title="Open Pill Bluetooth" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "bluetooth" ""; }
+
   // Use spawn-sh to run a shell command. Do this if you need pipes, multiple commands, etc.
   // Note: the entire command goes as a single argument. It's passed verbatim to `sh -c`.
   // For example, this is a standard bind to toggle the screen reader (orca).
   Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; }
 
   // Example volume keys mappings for PipeWire & WirePlumber.
   // The allow-when-locked=true property makes them work even when the session is locked.
   // Using spawn-sh allows to pass multiple arguments together with the command.
   // "-l 1.0" limits the volume to 100%.
   XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0 && touch /tmp/qsosd-vol"; }
