# Elena networks window (R4 of the SwayFX + eww replication)

Date: 2026-10-14

## Outcome
The bottom bar's network button opens her networks window (right side, above the
bar) and Settings loses its Network tab. Measured by: node gates for the nmcli
parser and signal buckets pass; a render check shows the list rows, empty
state, bandwidth row and toolbar in the expected colors; `popup-ipc-check.sh`
passes; live: the window opens, lists real networks (read-only `nmcli`), and
dismisses by every path.

## Reference
`config/eww/windows/networks.{yuck,scss}` and `scripts/networks.sh` in
github.com/elenapan/dotfiles (master, 2025-09-07). Scale S = `Config.elenaScale`
(1.5), sizes through `Config.dp()`, accents through `Colors.elenaAccent(n)`.

## Decisions (user, 2026-10-14)
- VPN button opens the NetworkManager GUI (`nm-connection-editor`); the user
  has no VPN. It shows "vpn on/off" from `NetworkStatusService`.
- Remove the Settings Network tab; her window is the only network UI. The nmcli
  logic from `bar/WifiPanel.qml` moves into one service.
- Her widgets, our palette.

## Window
`bar/NetworksWindow.qml`: layer Overlay, anchors right and bottom, width
`dp(300)`, bottom margin `Config.bottomBarHeight + dp(10)`, left corners radius
`dp(20)`, color `Colors.surface`, exclusion Ignore, keyboard focus on demand
while open.

- **Dismiss:** Esc, middle click, click outside (shield), the bar button again.
- **List:** area min height 4 rows of `dp(60)`, `surfaceContainer`, radius
  `dp(8)`, vertical scroll. Empty state: symbol and "No networks found".
- **Row:** `dp(6)` left border by signal bucket (excellent and good x4, ok x3,
  bad x8; the connected row highlighted), round type icon (saved or new), name
  truncated at 22 characters (19 + "..."), buttons at the right:
  - not connected: connect (x2); connected: disconnect (x1); saved: forget (x3).
- **Connect:** saved or open networks connect directly; a new secured network
  expands an inline passphrase row (Enter connects, Esc cancels, text masked);
  a failure runs `notify-send -u low Networks "Could not connect to <name>"`.
- **Forget:** an inline Yes/No confirmation row.
- **Bandwidth row:** down arrow x1 and up arrow x2 with MB/s from
  `SystemMetricsService` (all interfaces; her `wlan0` only).
- **Toolbar** (height `dp(66)`, buttons spaced `dp(6)`):
  - vpn: "vpn on|off", click runs `nm-connection-editor`;
  - scan: "N net(s)", loading state while `nmcli dev wifi rescan` plus 5 list
    polls (1 s apart) run;
  - speedtest: `xdg-open https://www.speedtest.net`;
  - ping: streams `ping -c 10 -w 30 1.1.1.1` into the label (`NNms`, final
    average, `dc` when unreachable); ignores clicks while running.

## Data and files
| File | Role |
|---|---|
| `config/NetworkList.js` (pure) | `parseWifiList(text)`, `parseSaved(text)`, `merge(wifi, saved)`, `signalBucket(signal)`, `shortName(name)`, `parsePingLine(line)` |
| `config/NetworkListService.qml` | singleton: `networks`, `scanning`, `pingText`, `pinging`, `connect(name, pass)`, `disconnect(name)`, `forget(name)`, `scan()`, `ping()`; `active` flag set by the window; nmcli processes |
| `bar/NetworksWindow.qml` | window |
| `bar/networks/{NetworkRow,ToolbarButton,BandwidthRow,PassphraseRow}.qml`, `NetworksContent.qml` (window-less, render-checkable) | pieces |
| `shell.qml` | instance, `networkRequested` toggles it, `forgetPrompt` IPC drives it, `openPopup === "networks"` |
| deleted | `bar/WifiPanel.qml`, `bar/settings/NetworkTab.qml`, the Settings Network tab entry and search entries, tests naming them |
| kept | `NetworkStatusService.qml` (bar state), `NetworkTab`-independent Settings tabs (indices shift: update tests, README, any `settingsTab` IPC use) |

`signalBucket`: signal >= 75 excellent, >= 50 good, >= 25 ok, else bad (nmcli
reports 0 to 100).

## Verification
- Node: `tests/networks/list.test.mjs` (nmcli terse parse with escaped colons,
  duplicate SSIDs keep the strongest, hidden SSID dropped, saved merge, active
  row selected, bucket edges at 0, 24, 25, 49, 50, 74, 75, 100, name
  truncation at 22/23, ping line parse for `time=12.3 ms` and the `rtt` summary
  and "Network is unreachable").
- Wiring: bar button toggles the window; Settings has no Network tab and no
  dangling tab indices; the removed files are gone.
- Render check (scratch HOME, fake `nmcli` fixtures through the service's
  command seam): rows per bucket border color, connected highlight, empty
  state, bandwidth values, toolbar labels; passphrase row appears for a new
  secured network and Esc closes it; mutation-proven.
- Existing gates: m3-qmllint, config-dump, settings-tabs tests, bottom-bar and
  sidebar renders, style-refs, popup-ipc-check.
- Live (after the user's cold restart): window opens from the bar button and
  IPC, lists real networks, scan runs, ping runs, every dismiss path, journal
  clean. Connect, disconnect and forget are NOT exercised live (they would drop
  the user's connection); they are proven against the fake `nmcli`.

## Risks
Removing the tab shifts Settings tab indices (tests, README, IPC callers).
Real connect paths are only fixture-tested; a typo would show up only on first
live use, so the commands stay byte-identical to `WifiPanel.qml`'s working
ones where possible.

## Out of scope
Alarms window (R5), VPN profile management, captive-portal handling, multi
monitor, hidden-SSID entry.

## Usage
Click the bar's network button (again to close). Dev IPC: `qs ipc call shell
forgetPrompt <name>` opens the window with the forget confirmation shown.
