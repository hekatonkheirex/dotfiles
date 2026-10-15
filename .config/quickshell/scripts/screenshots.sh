#!/usr/bin/env bash
# Capture README screenshots from the live shell into docs/screenshots/.
# Usage: scripts/screenshots.sh   (needs grim, a running shell, niri)
set -euo pipefail
out="$(cd "$(dirname "$0")/.." && pwd)/docs/screenshots"
mkdir -p "$out"
ipc() { qs ipc call shell "$@" >/dev/null; }
shot() {
  sleep 1.2
  grim -t jpeg -q 88 "$out/$1.jpg"
  echo "$1"; ipc dismissPopups; sleep 0.6
}

# Shoot from an empty workspace so no window content leaks into the images.
read -r orig empty < <(niri msg --json workspaces | python3 -c '
import json, sys
ws = json.load(sys.stdin)
orig = next(w["idx"] for w in ws if w["is_focused"])
empty = next((w["idx"] for w in ws if w["active_window_id"] is None), "")
print(orig, empty)')
[ -n "$empty" ] || { echo "no empty workspace; close windows first" >&2; exit 1; }
trap 'niri msg action focus-workspace "$orig"' EXIT
niri msg action focus-workspace "$empty"; sleep 0.8

ipc dismissPopups; sleep 0.6
shot desktop
ipc launcher;            shot launcher
ipc openSidebarPage 0;   shot sidebar-home
ipc openSidebarPage 1;   shot sidebar-agenda
ipc openSidebarPage 2;   shot sidebar-media
ipc settings;            shot settings
ipc quickmenu;           shot powermenu
ipc wallpapers;          shot wallpapers
