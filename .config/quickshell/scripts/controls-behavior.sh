#!/usr/bin/env bash
# Usage: controls-behavior.sh [quickshell-root]
# Exercises the single Elena control implementation in a throwaway HOME.
set -u
root=$(realpath "${1:-$(dirname "$0")/..}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$home/cfg/"
cp "$root/tests/controls-behavior/shell.qml" "$home/cfg/shell.qml"
printf '{"colorSource":"fixed","colorPalette":"material3","themePreference":1}\n' \
  > "$home/.config/quickshell/settings.json"
out=$(HOME="$home" timeout 40 qs -p "$home/cfg/shell.qml" 2>&1 | grep -oE '(PASS|FAIL|DONE) .*')
n=$(grep -c '^PASS' <<<"$out"); f=$(grep -c '^FAIL' <<<"$out")
if ! grep -q '^DONE' <<<"$out"; then echo "FAIL elena: never reported DONE"; exit 1
elif [ "$f" -gt 0 ]; then echo "FAIL elena: $f failed ($n passed)"; grep '^FAIL' <<<"$out"; exit 1
else echo "ok   elena: $n checks"; fi
