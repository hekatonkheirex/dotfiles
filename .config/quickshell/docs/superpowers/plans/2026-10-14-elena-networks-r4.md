# Elena networks window (R4) Implementation Plan

**Status: DONE (2026-10-14).** R4 implementation and final fixes are committed
and pushed through `5a13c5ea`. Live read-only window/list/scan/ping/dismissal
checks and fixture command/render checks passed. Connect, disconnect and forget
were never exercised against the live connection. Final review was inline;
configured review providers were unavailable. Existing Wayland text-input
warnings and the separate RSS investigation are not unresolved R4 features.
The original checklists below are the implementation recipe, not current
backlog. Next phase: R5 alarms. Claude's memory note and index are synchronized.


> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Her networks window replaces the Settings Network tab; the bar's network button toggles it.

**Architecture:** Pure `config/NetworkList.js` parses nmcli output; singleton `config/NetworkListService.qml` owns every nmcli process behind one command seam (so a render stage can feed fixtures); window-less `bar/networks/NetworksContent.qml` is hosted by `bar/NetworksWindow.qml` (Overlay layer). `bar/WifiPanel.qml` and the Settings Network tab are removed once the service carries their working commands.

**Tech Stack:** Quickshell QML (Qt 6.12), plain JS pure modules, node gate tests, scratch-HOME render scripts.

Spec: `docs/superpowers/specs/2026-10-14-elena-networks-r4-design.md`. Reference: github.com/elenapan/dotfiles `config/eww/windows/networks.{yuck,scss}`, `scripts/networks.sh` (shallow clone also under `/tmp/claude-1000/-home-mura--config-quickshell/8cd8fea9-cfb2-4e19-9657-170b9c0b16ef/scratchpad/elenapan-ref/dotfiles`).

## Global Constraints
- VCS is yadm only. Commit with `yadm add <paths>`, `yadm commit`, `yadm push`; plain git needs `GIT_DIR=$HOME/.local/share/yadm/repo.git GIT_WORK_TREE=$HOME`. Never stage `settings.json`, Kvantum, kitty, niri, btop or starship files; never edit niri files.
- Sizes through `Config.dp(N)` (S = `Config.elenaScale` 1.5); accents through `Colors.elenaAccent(n)` (x1 error, x2 secondary, x3 tertiary, x4 primary, x8 outline).
- Signal buckets (nmcli 0..100): >= 75 excellent, >= 50 good, >= 25 ok, else bad. Border colors: excellent and good x4, ok x3, bad x8. Name truncation: longer than 22 characters becomes first 19 plus "...".
- Window: width `dp(300)`, bottom margin `Config.bottomBarHeight + dp(10)`, anchors right and bottom, Overlay layer, exclusion Ignore, left corners radius `dp(20)`, list min height 4 rows of `dp(60)` on `surfaceContainer` radius `dp(8)`, toolbar height `dp(66)`.
- Toolbar: vpn opens `nm-connection-editor`; scan = `nmcli dev wifi rescan` plus 5 list polls 1 s apart; speedtest = `xdg-open https://www.speedtest.net`; ping = `ping -c 10 -w 30 1.1.1.1` streamed.
- Connect commands must stay byte-identical to the working ones in `bar/WifiPanel.qml` (`nmcli dev wifi connect '<ssid>' [password '<pw>']`, `nmcli device disconnect`, `nmcli connection delete`); connect/disconnect/forget are never run against the live shell in tests (they drop the user's connection): fixture-test them only.
- QML saves hot-reload the live shell: every saved state valid; new types in their own files (no inline `component`). The popup route name is `"networks"`.
- No em dashes, no new dependency, no `rm -rf`, no `--no-verify`. Every task ships tests in the same commit; render checks are mutation-proven.

---

### Task 1: NetworkList.js and gate tests

**Files:**
- Create: `config/NetworkList.js`, `tests/networks/list.test.mjs`

**Interfaces:**
- Produces (`.pragma library`, style of `config/SidebarPages.js`):
  - `parseWifiList(text)` -> array of `{name, signal, secure, active}` from `nmcli -t -e yes -f active,ssid,signal,security dev wifi list` output (colons and backslashes escaped with a backslash; read how `bar/WifiPanel.qml` `parseTerseFields`/`parseWifiList` do it and keep the same escaping rules). Empty or hidden SSID rows dropped; duplicate SSIDs collapse to the strongest signal, `active` true if any duplicate is active; sorted by active first then signal descending. `secure` is true when security is non-empty and not `--`.
  - `parseSaved(text)` -> array of saved Wi-Fi connection names from `nmcli -t -e yes -f NAME,TYPE,AUTOCONNECT,DEVICE connection show` (type `802-11-wireless` or `wifi`).
  - `merge(wifi, saved)` -> wifi rows plus `saved` boolean.
  - `signalBucket(signal)` -> `"excellent" | "good" | "ok" | "bad"`.
  - `shortName(name)` -> name or first 19 chars + "..." when length > 22.
  - `parsePingLine(line)` -> `{kind: "time", ms: <int rounded>}` for `time=12.4 ms`, `{kind: "avg", ms}` for an `rtt min/avg/max` summary, `{kind: "unreachable"}` for "Network is unreachable", else `{kind: "none"}`.

- [ ] **Step 1:** Write `tests/networks/list.test.mjs` first (style of `tests/sidebar/pages.test.mjs`: `new Function` over the source minus the pragma). Cases: escaped colon in an SSID (`Home\:5G`), duplicate SSID keeps strongest and active, empty SSID dropped, `--` security means open, ordering, saved parse picks only wifi rows, merge flags saved, bucket edges at 0, 24, 25, 49, 50, 74, 75, 100, shortName at 22 and 23 characters, parsePingLine for `64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=12.4 ms` (12), `rtt min/avg/max/mdev = 11.0/12.6/14.2/1.0 ms` (avg 13), "ping: connect: Network is unreachable", and a junk line.
- [ ] **Step 2:** Run `node tests/networks/list.test.mjs`; expected FAIL (file missing).
- [ ] **Step 3:** Implement `config/NetworkList.js` to pass.
- [ ] **Step 4:** Run the test, `bash scripts/m3-qmllint-gate.sh`; commit and push `networks R4: parser and signal buckets`.

---

### Task 2: NetworkListService and content pieces with a render check

**Files:**
- Create: `config/NetworkListService.qml`, `bar/networks/{NetworksContent,NetworkRow,ToolbarButton,BandwidthRow,PassphraseRow}.qml`, `tests/networks/shell.qml`, `scripts/networks-render.sh`, `tests/networks/wiring.test.mjs`
- Modify: `config/qmldir` (register the singleton like `SystemMetricsService`), `bar/networks/qmldir` if sibling folders use one

**Interfaces:**
- Consumes: `NetworkList.js` (Task 1), `SystemMetricsService` (net rate), `NetworkStatusService.vpn`, `Config.dp`, `Colors.elenaAccent`, `BottomBarFonts`.
- Produces:
  - `NetworkListService` singleton: `property bool active`, `property var networks` (merged rows), `property bool scanning`, `property string pingText` (default "ping"), `property bool pinging`, `property string lastError`; functions `refresh()`, `scan()`, `connect(name, password)`, `disconnect()`, `forget(name)`, `ping()`. Every process is built from a `property var commandFor: function(kind, args) -> [argv]` seam so the render stage can substitute fixture commands. `active` false stops all polling.
  - `NetworksContent` (Item): properties `networksModel`, `scanning`, `pingText`, `vpnOn`, `downText`, `upText`, `passphraseFor` (name or ""), `forgetFor` (name or ""); signals `connectRequested(name, password)`, `disconnectRequested()`, `forgetConfirmed(name)`, `scanRequested()`, `speedtestRequested()`, `pingRequested()`, `vpnRequested()`, `dismissRequested()`.

- [ ] **Step 1:** Write failing checks in `scripts/networks-render.sh` (scratch HOME, stage `tests/networks/shell.qml` emitting GEOM lines, modeled on `scripts/powermenu-render.sh`): row border color per bucket (x4, x4, x3, x8) for four fixture rows; connected row highlighted; saved row shows forget, connected shows disconnect, others connect (button counts and accent pixels x2, x1, x3); empty state text pixels with an empty model; bandwidth texts present; toolbar labels ("vpn off", "2 nets", "speedtest", "ping"); a new secured network click shows the passphrase row masked and Esc hides it; forget shows Yes/No. Run it; expected FAIL.
- [ ] **Step 2:** Implement the service (commands copied from `bar/WifiPanel.qml`: list `nmcli -t -e yes -f active,ssid,signal,security dev wifi list`, saved `nmcli -t -e yes -f NAME,TYPE,AUTOCONNECT,DEVICE connection show`, connect, disconnect `nmcli device disconnect <dev>` with the device found as WifiPanel does, forget `nmcli connection delete`), the pieces and the stage. Refresh on `active`, on NM change through the existing `NetworkStatusService` monitor signal where available (else a 10 s timer while active), and after connect/disconnect/forget. Failures set `lastError` and run `notify-send -u low Networks "Could not connect to <name>"`.
- [ ] **Step 3:** Run `bash scripts/networks-render.sh` and `node tests/networks/*.test.mjs`; all pass. Mutation-prove: swap two bucket colors, drop the connected highlight, break the truncation, remove the passphrase masking; each fails the render check.
- [ ] **Step 4:** `bash scripts/m3-qmllint-gate.sh`, `scripts/style-refs.sh --elena`, `scripts/config-dump.sh check`; commit and push `networks R4: service and window content`.

---

### Task 3: NetworksWindow, shell wiring, Settings tab and WifiPanel removed

**Files:**
- Create: `bar/NetworksWindow.qml`
- Modify: `shell.qml` (instance, `networkRequested`, `forgetPrompt` IPC, route `"networks"`, bottom bar), `bar/SettingsPanel.qml` (remove the Network tab definition, search entries, `forgetPrompt` plumbing; renumber every `tab:`/`currentTab` index above 4), `bar/settings/*` and tests that name tab indices, `README.md`, `tests/settings-tabs/*`, `tests/elena/test.mjs` if affected
- Delete: `bar/WifiPanel.qml`, `bar/settings/NetworkTab.qml`
- Test: `tests/networks/wiring.test.mjs`, existing settings-tabs tests

**Interfaces:**
- Consumes: `NetworksContent`, `NetworkListService`.
- Produces: `NetworksWindow` with `signal dismissed()`; route `"networks"`; IPC `forgetPrompt(name)` opens the window with `forgetFor = name`.

- [ ] **Step 1:** Add failing wiring assertions: `shell.qml` instantiates `NetworksWindow` with `visible: bar.openPopup === "networks" && !lockScreen.locked && !lockScreen.compositorLocked`; `onNetworkRequested` toggles `"networks"` and no longer sets `settingsPanel.currentTab = 4`; `bar/WifiPanel.qml` and `bar/settings/NetworkTab.qml` do not exist; `SettingsPanel.qml` has no `label: "Network"` tab; the tab definitions count dropped by one and every `tab:` search index is below the new count; `forgetPrompt` references the new window.
- [ ] **Step 2:** Implement the window: Overlay layer, anchors right and bottom, keyboard focus on demand only while visible, `NetworkListService.active` bound to visibility, Esc/middle click/click outside (reuse the popup shield pattern of the sidebar) dismiss. Wire `shell.qml`, then remove the Settings tab and WifiPanel in one save after nothing references them (grep first); renumber the indices and fix tests, README and `settingsTab` IPC doc.
- [ ] **Step 3:** Run every gate: node tests, `scripts/networks-render.sh`, `scripts/m3-qmllint-gate.sh`, `scripts/config-dump.sh check`, `scripts/style-refs.sh --elena`, `scripts/popup-ipc-check.sh` (extend it with the `networks` route if it lists popups), sidebar and bottom-bar renders, `tests/settings-tabs`. Live read-only check against the hot-reloaded shell: open the window over IPC and confirm `niri msg layers` shows its layer, `nmcli` list output renders rows, close it; do NOT trigger connect, disconnect or forget.
- [ ] **Step 4:** Commit and push `networks R4: window, Settings tab removed`.

---

### Task 4: Docs, live verification, final review

- [ ] **Step 1:** README: networks window section, bottom bar button table (network opens the window), Settings tab list and IPC rows; remove WifiPanel mentions.
- [ ] **Step 2:** After the user's cold restart: `bash scripts/popup-ipc-check.sh`; open the window from the bar button, confirm real networks listed, scan and ping run, every dismiss path; journal clean; RSS sample. Report connect/disconnect/forget as fixture-tested only.
- [ ] **Step 3:** Final opus whole-branch review of the R4 range; one fix wave.
- [ ] **Step 4:** Update the memory note and index; commit and push.
