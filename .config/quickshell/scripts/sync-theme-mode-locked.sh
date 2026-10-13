#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=theme-sync-lock.sh
source "$script_dir/theme-sync-lock.sh"

mode="${1:-auto}"
notify_mode="${2:-}"
sync_sddm="${3:-}"

if ! bash "$script_dir/sync-niri-shape.sh"; then
  printf 'Could not clear the obsolete Niri shape override; keeping the existing file.\n' >&2
fi

# This is the external Matugen asset family, not a selectable shell style.
args=("$mode" "$notify_mode" material3)
[[ -n "$sync_sddm" ]] && args+=("$sync_sddm")
exec "$HOME/.local/bin/sync-theme-mode.sh" "${args[@]}"
