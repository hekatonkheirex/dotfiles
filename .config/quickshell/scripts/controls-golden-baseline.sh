#!/usr/bin/env bash
# Usage: controls-golden-baseline.sh update|check
# Keeps the controls golden baseline outside the repo (PNGs are per-machine:
# fonts and Qt version change pixels) in ${QS_GOLDEN_DIR:-~/.local/state/quickshell-golden}/controls.
#   update  render the current tree and replace the baseline
#   check   render the current tree and compare against the baseline
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
base="${QS_GOLDEN_DIR:-$HOME/.local/state/quickshell-golden}/controls"
case "${1:-}" in
  update)
    rm -rf "$base"; "$root/scripts/controls-golden.sh" "$root" "$base" >/dev/null
    echo "baseline updated: $base ($(ls "$base" | wc -l) images)" ;;
  check)
    [ -d "$base" ] || { echo "no baseline at $base; run: $0 update" >&2; exit 2; }
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    "$root/scripts/controls-golden.sh" "$root" "$tmp" >/dev/null
    python3 "$root/scripts/controls-golden-compare.py" "$base" "$tmp" ;;
  *) echo "usage: $0 update|check" >&2; exit 2 ;;
esac
