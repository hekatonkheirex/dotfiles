# Task 8 Report: Niri keybinds for the 4 new pill surfaces

## Status: DONE

## Step 1: Key collision check

Read the full `binds { ... }` block in `~/.config/niri/keybinds.kdl` (grep of every `Mod+` line, 286 lines total).

Checked all four brief-suggested keys against the full bind list:

- `Mod+Shift+B` (battery) — free. Used.
- `Mod+Shift+N` (brightness) — free. Used.
- `Mod+Shift+W` (wifi) — free (`Mod+W` alone is `close-window`, but `Mod+Shift+W` was unbound). Used.
- `Mod+Shift+U` (bluetooth) — **collision**. Already bound at line 137 to `move-workspace-down`. Substituted with `Mod+Shift+T` ("blueTooth") — verified free (only `Mod+T` alone, bound to Nautilus, existed; `Mod+Shift+T` was unbound).

## Step 2: Binds added

Inserted immediately after the existing `Mod+Shift+Escape` (hide) line in `~/.config/niri/keybinds.kdl`, matching the exact existing spawn/ipc syntax pattern:

```kdl
  // Pill shell (Quickshell -p pill): battery/brightness/wifi/bluetooth surfaces.
  // Mod+Shift+U collides with move-workspace-down (below), so bluetooth uses Mod+Shift+T instead.
  Mod+Shift+B hotkey-overlay-title="Open Pill Battery" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "battery" ""; }
  Mod+Shift+N hotkey-overlay-title="Open Pill Brightness" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "brightness" ""; }
  Mod+Shift+W hotkey-overlay-title="Open Pill Wifi" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "wifi" ""; }
  Mod+Shift+T hotkey-overlay-title="Open Pill Bluetooth" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "bluetooth" ""; }
```

## Step 3: Validate and reload

```
$ niri validate
INFO niri: config is valid
EXIT:0

$ niri msg action load-config-file
EXIT:0
```

## Step 4: End-to-end verification

Found a live `qs -p /home/mura/.config/quickshell/pill` instance already running (PID 235563, Rodrigo's active session). Did not kill it — tested directly against it via IPC (read-only from the file's perspective, exercises the running shell):

```
$ qs -p /home/mura/.config/quickshell/pill ipc call pill battery ""     -> exit 0
$ qs -p /home/mura/.config/quickshell/pill ipc call pill brightness ""  -> exit 0
$ qs -p /home/mura/.config/quickshell/pill ipc call pill wifi ""        -> exit 0
$ qs -p /home/mura/.config/quickshell/pill ipc call pill bluetooth ""   -> exit 0
$ qs -p /home/mura/.config/quickshell/pill ipc call pill hide          -> exit 0
```

Confirmed PID 235563 still running afterward (`pgrep -af "qs -p"`), untouched.

All four new IPC targets (`battery`, `brightness`, `wifi`, `bluetooth`) exist and respond correctly on the running shell, and `hide` closes them. Since niri config reloaded cleanly and the same `spawn "qs" "-p" ... "ipc" "call" "pill" <target> ""` pattern is used as the existing working `Mod+M` mixer bind, the keybinds are confirmed functionally correct end to end (the only untested link is the physical key press itself, which is a niri-level guarantee already exercised by the pre-existing `Mod+M`/`Mod+Shift+Escape` binds using the identical spawn pattern).

## Step 5: Commit

```
yadm add -u ~/.config/niri/keybinds.kdl
yadm commit -m "Add niri keybinds for battery, brightness, wifi, bluetooth pill surfaces ..."
```

Commit: `2b41cfc8`

Note: `yadm status` after commit showed unrelated pre-existing modified files (Kvantum theme, `niri/colors.kdl`, `niri/windowrules.kdl`, `layout`) from other live matugen/session activity — not touched by this task, left as-is per scope.

## Summary of substitution

Brief suggested `Mod+Shift+U` for bluetooth (avoiding `B`, taken by battery). That key is already bound to `move-workspace-down`. Substituted `Mod+Shift+T` (blueTooth) instead, documented in both the KDL comment and the commit message.
