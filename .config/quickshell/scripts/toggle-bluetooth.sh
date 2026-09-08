#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  runtime_dir="$XDG_RUNTIME_DIR/quickshell"
else
  runtime_dir="$HOME/.cache/quickshell/runtime"
fi

umask 077
mkdir -p -- "$runtime_dir"
if [[ "$(stat -c '%a' -- "$runtime_dir" 2>/dev/null || true)" != "700" ]]; then
  chmod 700 -- "$runtime_dir"
fi
exec 9>"$runtime_dir/radio-toggle.lock"
flock -n 9 || exit 0

bluetooth_enabled() {
  bluetoothctl show | grep -q 'Powered: yes'
}

if bluetooth_enabled; then
  bluetoothctl power off
  expected=off
else
  bluetoothctl power on
  expected=on
fi

for ((attempt = 0; attempt < 100; attempt++)); do
  if [[ "$expected" == "on" ]] && bluetooth_enabled; then
    exec "$script_dir/emit-trigger" qsosd-bluetooth
  fi
  if [[ "$expected" == "off" ]] && ! bluetooth_enabled; then
    exec "$script_dir/emit-trigger" qsosd-bluetooth
  fi
  sleep 0.05
done

printf 'Timed out waiting for Bluetooth power state: %s\n' "$expected" >&2
exit 1
