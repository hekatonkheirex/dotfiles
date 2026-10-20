# Launcher

`bar/LauncherPopup.qml` is the window. Everything it decides lives in `config/launcher/*.js` (pure, `.pragma library`, covered by `tests/launcher/`).

## What you type

| Input | Result |
|---|---|
| plain text | one ranked list: calculator, quicklink query, apps, commands, windows, snippets, quicklinks. Fuzzy on names, word-start and prefix first. |
| `2+2*7`, `20% of 150`, `100 + 10%`, `sqrt(16)`, `5 km to mi`, `100 f to c` | calculator row on top. Enter copies the result. |
| `gh quickshell` | quicklink: first word is the keyword, the rest fills `{query}`. |
| `ff` | alias (from `launcher.json`) always sorts first. |
| `:rocket` | emoji (1352 single code point emoji). Enter copies. |
| `>` | system actions (power, lock, theme, screenshots). Unchanged. |
| `;` | clipboard history through cliphist. Unchanged. |
| `@` | wallpaper filmstrip. Unchanged. |
| nothing | apps and commands, most used first. |

Fewer than 3 results and no calculation: fallback rows appear ("Search Google for ..."). Mark any quicklink `"fallback": true` to add it.

## Keys

`Ctrl+K` (also `Shift+F10`, `Menu`) opens the action panel for the selected row. Enter runs the first action. Existing keys are unchanged (`Ctrl+N/P`, `Tab`, `Alt+J/K`, `Esc`).

| Row | Actions |
|---|---|
| app | Open, Run in terminal, Copy launch command |
| calculator | Copy result, Copy expression and result |
| quicklink | Open link, Copy URL |
| snippet, emoji | Copy to clipboard, Paste into focused window (types it with `wtype`) |
| window | Switch to window, Close window |
| clipboard | Restore, Delete |

Window rows come from `niri msg -j windows`, read each time the launcher opens. Layout commands (maximize, fullscreen, center, float, width 25/33/50/66/75/100 %) act on the window niri reports as focused.

## `launcher.json`

Optional, at `~/.config/quickshell/launcher.json`. Copy `launcher.example.json`. Edits apply live, no restart. A malformed file is ignored, never fatal.

- `aliases`: `{ "ff": "Firefox" }`. Alias to app name (case-insensitive).
- `quicklinks`: `{ name, url, keyword?, fallback? }`. `url` must be `http`, `https` or `mailto`; anything else (`javascript:`, `file:`, `data:`) is dropped. `{query}` and `{clipboard}` are URL-encoded. A keyword equal to a built-in (`g`, `ddg`, `gh`, `yt`, `w`, `aw`) replaces it and keeps its fallback flag.
- `snippets`: `{ name, text, keyword? }`. Placeholders: `{date}`, `{time}`, `{datetime}`, `{day}`, `{clipboard}`, `{uuid}`, `{cursor}` (dropped). Expansion is single pass.

The clipboard is read only when a snippet or quicklink contains `{clipboard}`.

## History

Launches are ranked by use with a 14 day half life, capped so relevance still wins. Stored in `$XDG_STATE_HOME/quickshell/launcher-history.json` (default `~/.local/state/quickshell/`), 500 entries max. Calculator, emoji, typed quicklink queries and windows are never recorded. Delete the file to reset.

## Regenerating emoji

`python3 scripts/gen-emoji.py` rebuilds `config/launcher/EmojiData.js` from Unicode names and the installed Noto Color Emoji coverage. `tests/launcher/emoji-data.test.mjs` fails when it is stale.

## Not built

AI, extension store, file search, per-item hotkeys, in-launcher editing of quicklinks and snippets (edit the JSON), snippet auto-expansion while typing in other apps (Wayland has no portable hook), emoji ZWJ sequences and skin tones, currency conversion.

## Provenance

Feature scope came from inspecting `Raycast_2.8.2.0_arm64.dmg` with REA (`inspect_artifact`, `analyze_javascript_application`): the app bundles a Vite frontend with modules for quicklinks, snippets, clipboard history, calculator, emoji, window management and fallback commands, and a SoulverCore calculator backend. No Raycast code or assets are used. Behavior is written from observed feature names and public documentation.
