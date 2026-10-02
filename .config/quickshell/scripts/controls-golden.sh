#!/usr/bin/env bash
# Usage: controls-golden.sh <quickshell-root> <out-dir>
# Renders tests/controls-golden/shell.qml once per style under a throwaway
# $HOME and writes <out-dir>/<style>.png.
set -euo pipefail
root=$(realpath "$1"); out=$(mkdir -p "$2" && realpath "$2")
styles=("material3:classic" "nothing:classic" "nothing:evolution" "ghost:classic" "liquid-glass:classic")
for s in "${styles[@]}"; do
  style=${s%%:*}; variant=${s##*:}
  home=$(mktemp -d); mkdir -p "$home/.config/quickshell" "$home/cfg"
  cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
  cp "$root/tests/controls-golden/shell.qml" "$home/cfg/shell.qml"
  printf '{"themeStyle":"%s","nothingVariant":"%s","colorSource":"fixed","colorPalette":"material3","themePreference":1}\n' \
    "$style" "$variant" > "$home/.config/quickshell/settings.json"
  name="$style"; [ "$style" = nothing ] && name="nothing-$variant"
  HOME="$home" GOLDEN_OUT="$out/$name.png" QS_NO_RELOAD_POPUP=1 \
    timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
  [ -s "$out/$name.png" ] || { echo "FAIL $name"; tail -5 "$home/qs.log"; }
  rm -rf "$home"
done
ls -1 "$out"
