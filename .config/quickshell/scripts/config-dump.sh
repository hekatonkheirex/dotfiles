#!/usr/bin/env bash
# Usage: config-dump.sh capture|check [quickshell-root]
# Dumps every Config/Colors property under the elena style in a scratch HOME.
#   capture  write tests/elena/config-dump.baseline.json
#   check    dump twice (determinism), compare with the baseline through
#            config-dump-compare.py and tests/elena/config-dump.allow.json
set -euo pipefail
mode=${1:-}
root=$(realpath "${2:-$(dirname "$0")/..}")

names() { # property names declared in a QML file (properties only, not aliases of functions)
  grep -oE '^[[:space:]]*(readonly )?property [A-Za-z.<>]+ [A-Za-z0-9_]+' "$1" | awk '{print $NF}' | sort -u
}

dump_once() {
  local home; home=$(mktemp -d)
  mkdir -p "$home/.config/quickshell" "$home/cfg"
  cp -r "$root/config" "$home/cfg/"
  cp "$root/tests/elena/config-dump/shell.qml" "$home/cfg/shell.qml"
  {
    printf '.pragma library\nvar config = ['
    names "$root/config/Config.qml" | sed 's/.*/"&"/' | paste -sd, -
    printf '];\nvar colors = ['
    names "$root/config/Colors.qml" | sed 's/.*/"&"/' | paste -sd, -
    printf '];\n'
  } > "$home/cfg/names.js"
  # Unknown legacy settings must not select a removed style or density.
  cp "$root/tests/elena/config-dump.legacy.json" "$home/.config/quickshell/settings.json"
  HOME="$home" XDG_CURRENT_DESKTOP=niri XDG_SESSION_DESKTOP=niri timeout 40 qs -p "$home/cfg/shell.qml" 2>&1 \
    | sed -n 's/^.*DUMP //p' | head -1
  rm -rf "$home"
}

a=$(dump_once)
[ -n "$a" ] || { echo "config-dump: no DUMP line (qs failed)" >&2; exit 2; }
case "$mode" in
  capture)
    printf '%s\n' "$a" > "$root/tests/elena/config-dump.baseline.json"
    echo "baseline written: $(python3 -c 'import json,sys;print(len(json.loads(sys.argv[1])))' "$a") keys" ;;
  check)
    b=$(dump_once)
    [ "$a" = "$b" ] || { echo "config-dump: not deterministic between two runs" >&2; exit 2; }
    tmp=$(mktemp); printf '%s\n' "$a" > "$tmp"
    rc=0
    python3 -I "$root/scripts/config-dump-compare.py" "$root/tests/elena/config-dump.baseline.json" "$tmp" \
      "$root/tests/elena/config-dump.allow.json" || rc=$?
    rm -f "$tmp"; exit $rc ;;
  *) echo "usage: $0 capture|check [root]" >&2; exit 2 ;;
esac
