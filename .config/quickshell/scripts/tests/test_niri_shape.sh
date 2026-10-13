#!/usr/bin/env bash
# Gate: the single-style shell leaves Niri's ordinary window rules intact.
set -euo pipefail
here="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
export NIRI_CONFIG_DIR="$tmp/niri"
run() { bash "$here/../sync-niri-shape.sh"; }

run
if grep -q 'window-rule' "$tmp/niri/style.kdl"; then
  echo "FAIL: shell left a window-rule"; exit 1
fi
before="$(stat -c %i "$tmp/niri/style.kdl")"
run
[ "$before" = "$(stat -c %i "$tmp/niri/style.kdl")" ] || { echo "FAIL: unchanged file rewritten"; exit 1; }
echo "PASS niri-shape"
