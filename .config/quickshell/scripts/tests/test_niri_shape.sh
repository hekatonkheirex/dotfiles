#!/usr/bin/env bash
# Gate: scripts/sync-niri-shape.sh squares Niri windows only for dwm.
set -euo pipefail
here="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
export NIRI_CONFIG_DIR="$tmp/niri"
run() { bash "$here/../sync-niri-shape.sh" "$1"; }

run dwm
grep -q 'geometry-corner-radius 0' "$tmp/niri/style.kdl" || { echo "FAIL dwm: no radius 0"; exit 1; }
grep -q 'clip-to-geometry true' "$tmp/niri/style.kdl" || { echo "FAIL dwm: no clip"; exit 1; }

before="$(stat -c %i "$tmp/niri/style.kdl")"
run dwm
[ "$before" = "$(stat -c %i "$tmp/niri/style.kdl")" ] || { echo "FAIL dwm rewrote unchanged file"; exit 1; }

for s in material3 nothing ghost liquid-glass elena ""; do
  run "$s"
  if grep -q 'window-rule' "$tmp/niri/style.kdl"; then echo "FAIL '$s' left a window-rule"; exit 1; fi
done
echo "PASS niri-shape"
