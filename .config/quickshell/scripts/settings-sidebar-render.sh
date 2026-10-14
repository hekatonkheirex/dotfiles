#!/usr/bin/env bash
# Usage: settings-sidebar-render.sh [quickshell-root]   (KEEP_PNG=path keeps the render)
# Renders the six Settings pages side by side at the sidebar width under the
# elenapan palette in a scratch HOME (tests/settings-sidebar/shell.qml), fails
# on any QML error or any item that overflows its page cell.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
real_home=$HOME
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg" "$home/.local/share" "$home/run"
chmod 700 "$home/run"
ln -s "${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}" "$home/run/$WAYLAND_DISPLAY"
cp -r "$root/config" "$root/bar" "$root/scripts" "$home/cfg/"
cp "$root/tests/settings-sidebar/shell.qml" "$home/cfg/shell.qml"
mkdir -p "$home/.config/fontconfig"
ln -s "$real_home/.config/fontconfig/conf.d" "$home/.config/fontconfig/conf.d"
ln -s "$real_home/.local/share/fonts" "$home/.local/share/fonts"
printf '{"colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" XDG_RUNTIME_DIR="$home/run" GOLDEN_OUT="$home/pages.png" QS_NO_RELOAD_POPUP=1 \
  timeout 40 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/pages.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
[ -z "${KEEP_PNG:-}" ] || cp "$home/pages.png" "$KEEP_PNG"
[ -z "${KEEP_LOG:-}" ] || cp "$home/qs.log" "$KEEP_LOG"
errpat='TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR|Binding loop|Invalid property|Non-existent attached|Cannot anchor'
errs=$(grep -E "$errpat" "$home/qs.log" | head -8 || true)
if [ -n "$errs" ]; then echo "FAIL: QML errors"; echo "$errs"; exit 1; fi
grep -q "DONE settings-sidebar 0 fail" "$home/qs.log" || { grep -E "PASS |FAIL |OVERFLOW|DONE" "$home/qs.log" | sed "s/^.*\(OVERFLOW\|FAIL\|DONE\|PASS\)/\1/" | head -30; tail -5 "$home/qs.log"; exit 1; }
echo "ok   six pages render, no overflow"
