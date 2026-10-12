#!/usr/bin/env bash
# Run the actual usage service without starting the desktop or making requests.
set -euo pipefail
root=$(realpath "$(dirname "$0")/..")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -r "$root/config" "$work/config"
cp "$root/tests/llm-usage/shell.qml" "$work/shell.qml"
output=$(QT_QPA_PLATFORM=offscreen timeout 15 qs -p "$work/shell.qml" --no-color 2>&1)
printf '%s\n' "$output"
[[ "$output" == *"DONE 0 fail"* && "$output" != *"FAIL "* ]]
