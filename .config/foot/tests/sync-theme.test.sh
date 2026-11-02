#!/bin/bash
# Gate test: generated theme.ini matches kitty palette and foot accepts it.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export KITTY_DIR="$HOME/.config/kitty" FOOT_DIR="$tmp" NO_PUSH=1

"$here/sync-theme.sh" matugen light
ini="$tmp/theme.ini"
assert() { grep -qxF -- "$1" "$ini" || { echo "FAIL: missing '$1'"; exit 1; }; }

bg=$(awk '$1=="background"{print tolower(substr($2,2))}' "$KITTY_DIR/matugen-dark.conf")
c1=$(awk '$1=="color1"{print tolower(substr($2,2))}' "$KITTY_DIR/matugen-light.conf")
assert "initial-color-theme=light"
assert "[colors-dark]"; assert "[colors-light]"
assert "background=$bg"          # dark section from the dark file
assert "regular1=$c1"            # light section from the light file
[ "$(grep -c '^regular[0-7]=' "$ini")" = 16 ] || { echo "FAIL: regular count"; exit 1; }
[ "$(grep -c '^bright[0-7]=' "$ini")" = 16 ] || { echo "FAIL: bright count"; exit 1; }
[ "$(grep -c $'\033]4;' "$tmp/theme.osc")" -ge 1 ] || { echo "FAIL: osc"; exit 1; }
[ "$(tr '\033' '\n' <"$tmp/theme.osc" | grep -c '^\]4;')" = 16 ] || { echo "FAIL: osc palette count"; exit 1; }
echo "PASS"
