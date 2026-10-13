#!/usr/bin/env bash
# Usage: style-refs.sh [--elena] [paths...]
# Lists obsolete style references, excluding docs and regression metadata.
# --elena also checks the removed Elena guard. Exit 1 if any reader remains.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
pat='nothingDesign|nothingEvolution|ghostTheme|dwmTheme|liquidGlassTheme|material3Theme|themeStyle|nothingVariant|materialCompact|reduceTransparency|lockClockFace|liquidGlass[A-Z]|styleAccent|styleSurface|styleInk|styleOutline'
if [ "${1:-}" = "--elena" ]; then pat="$pat|elenaTheme"; shift; fi
cd "$root" || exit 2
if [ $# -gt 0 ]; then targets=("$@"); else targets=(.); fi
out=$(grep -rIicE "$pat" "${targets[@]}" --exclude-dir=docs --exclude-dir=.superpowers --exclude-dir=.git \
  --exclude=settings.json --exclude=config-dump.baseline.json --exclude=config-dump.allow.json \
  --exclude=config-dump.legacy.json --exclude=style-refs.sh 2>/dev/null | grep -v ':0$' | sort)
[ -z "$out" ] && { echo "style-refs: none"; exit 0; }
echo "$out"; exit 1
