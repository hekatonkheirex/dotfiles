#!/usr/bin/env bash
# Usage: controls-behavior.sh [quickshell-root]
# Runs tests/controls-behavior/shell.qml in every style under a throwaway $HOME.
# Exits non-zero if any check fails or a style never reports DONE.
set -u
root=$(realpath "${1:-$(dirname "$0")/..}")
fail=0
for s in material3:classic nothing:classic nothing:evolution ghost:classic liquid-glass:classic; do
  style=${s%%:*}; variant=${s##*:}
  home=$(mktemp -d); mkdir -p "$home/.config/quickshell" "$home/cfg"
  cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
  cp "$root/tests/controls-behavior/shell.qml" "$home/cfg/shell.qml"
  printf '{"themeStyle":"%s","nothingVariant":"%s","colorSource":"fixed","colorPalette":"material3","themePreference":1}\n' \
    "$style" "$variant" > "$home/.config/quickshell/settings.json"
  out=$(HOME="$home" timeout 40 qs -p "$home/cfg/shell.qml" 2>&1 | grep -oE '(PASS|FAIL|DONE) .*')
  rm -rf "$home"
  n=$(grep -c '^PASS' <<<"$out"); f=$(grep -c '^FAIL' <<<"$out")
  if ! grep -q '^DONE' <<<"$out"; then echo "FAIL $style-$variant: never reported DONE"; fail=1
  elif [ "$f" -gt 0 ]; then echo "FAIL $style-$variant: $f failed ($n passed)"; grep '^FAIL' <<<"$out" | sed 's/^/    /'; fail=1
  else echo "ok   $style-$variant: $n checks"; fi
done
exit $fail
