### Task 8: Niri keybinds for the 4 new surfaces

**Files:**
- Modify: `~/.config/niri/keybinds.kdl` (the file Plan 1's Task 7 actually edited — confirm it's still the file containing the `binds { ... }` block before editing)

**Interfaces:**
- Consumes: the four new `IpcHandler` functions from Task 7.

- [ ] **Step 1: Check for key collisions**

Read the full `binds { ... }` block in `~/.config/niri/keybinds.kdl` (and any other included niri KDL files) before picking keys. `Mod+B` is already bound to the browser. `Mod+M` and `Mod+Shift+Escape` are already bound to this plan's own mixer/hide (Plan 1). Suggested candidates — verify each is actually free before using it, and pick different ones (documenting the substitution, same as Plan 1's Task 7 did for the Escape collision) if any collide: `Mod+Shift+B` (battery), `Mod+Shift+N` (brightness — "N" for "iNtensity", avoiding the taken B), `Mod+Shift+W` (wifi), `Mod+Shift+U` (bluetooth — "U" since B is taken).

- [ ] **Step 2: Add the binds**

Add four bind lines to the `binds { ... }` block, immediately after Plan 1's `Mod+Shift+Escape` line, following the exact syntax pattern already there:

```kdl
  Mod+Shift+B hotkey-overlay-title="Open Pill Battery" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "battery" ""; }
  Mod+Shift+N hotkey-overlay-title="Open Pill Brightness" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "brightness" ""; }
  Mod+Shift+W hotkey-overlay-title="Open Pill Wifi" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "wifi" ""; }
  Mod+Shift+U hotkey-overlay-title="Open Pill Bluetooth" { spawn "qs" "-p" "/home/mura/.config/quickshell/pill" "ipc" "call" "pill" "bluetooth" ""; }
```

(Substitute any key that turned out to collide in Step 1 with a free one, updating both the bind and this note in your commit message.)

- [ ] **Step 3: Validate and reload**

```bash
niri validate
niri msg action load-config-file
```

- [ ] **Step 4: Verify end to end**

```bash
qs -p ~/.config/quickshell/pill > /tmp/claude-1000/-home-mura--config-quickshell/26cbbc8d-b6b7-41eb-a21f-736f579b2db2/scratchpad/pill-plan2-keybinds.log 2>&1 &
sleep 2
qs -p ~/.config/quickshell/pill ipc call pill battery ""
sleep 1
qs -p ~/.config/quickshell/pill ipc call pill hide
pkill -f "qs -p .*pill"
```

- [ ] **Step 5: Commit**

```bash
yadm add -u ~/.config/niri/keybinds.kdl
yadm commit -m "Add niri keybinds for battery, brightness, wifi, bluetooth pill surfaces"
```

---

## What this plan does NOT cover

Launcher, Power, Notification, Calendar, and the Menu/CommandCenter tabs — each structurally different from the simple Indicator+Popup pairs this plan handles (fuzzy search, a confirmation flow, `NotificationServer` integration, tabs) and left for separate follow-up plans. Multi-monitor behavior remains unverified (per Plan 1's final review) on this single-output machine.
