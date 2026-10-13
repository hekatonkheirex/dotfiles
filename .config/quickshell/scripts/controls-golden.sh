#!/usr/bin/env bash
# Usage: controls-golden.sh <quickshell-root> <out-dir>
# Renders Elena controls once under a throwaway HOME. The fallback semantic
# palette stays fixed so the existing per-machine baseline remains comparable.
set -euo pipefail
root=$(realpath "$1"); out=$(mkdir -p "$2" && realpath "$2")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/controls-golden/shell.qml" "$home/cfg/shell.qml"
printf '{"colorSource":"fixed","colorPalette":"material3","themePreference":1}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$out/elena.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$out/elena.png" ] || { echo "FAIL elena"; cat "$home/qs.log"; exit 1; }
printf '%s\n' "$out/elena.png"
