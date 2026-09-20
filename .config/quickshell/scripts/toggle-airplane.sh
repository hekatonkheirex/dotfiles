#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=runtime-dir.sh
source "$script_dir/runtime-dir.sh"
runtime_dir=$(quickshell_runtime_dir)
ensure_quickshell_runtime_dir "$runtime_dir"
exec 9>"$runtime_dir/radio-toggle.lock"
flock -n 9 || exit 0

wifi_enabled() {
  nmcli radio wifi | grep -q '^enabled$'
}

bluetooth_enabled() {
  bluetoothctl show | grep -q 'Powered: yes'
}

wait_for_state() {
  local expected=$1
  local attempt
  for ((attempt = 0; attempt < 100; attempt++)); do
    if [[ "$expected" == "on" ]] && wifi_enabled && bluetooth_enabled; then
      return 0
    fi
    if [[ "$expected" == "off" ]] && ! wifi_enabled && ! bluetooth_enabled; then
      return 0
    fi
    sleep 0.05
  done
  printf 'Timed out waiting for airplane-mode state: %s\n' "$expected" >&2
  return 1
}

if wifi_enabled; then
  nmcli radio wifi off
  bluetoothctl power off
  wait_for_state off
else
  nmcli radio wifi on
  bluetoothctl power on
  wait_for_state on
fi

exec "$script_dir/emit-trigger" qsosd-airplane
