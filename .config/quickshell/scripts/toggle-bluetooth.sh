#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=runtime-dir.sh
source "$script_dir/runtime-dir.sh"
runtime_dir=$(quickshell_runtime_dir)
ensure_quickshell_runtime_dir "$runtime_dir"
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
