#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=theme-sync-lock.sh
source "$script_dir/theme-sync-lock.sh"

# Mode changes select already-generated assets. Liquid Glass also refreshes the
# shared Matugen files here so btop's single mode-specific file cannot lag
# behind an automatic light/dark switch.
mode="${1:-auto}"
notify_mode="${2:-}"
ui_style="${3:-}"
sync_sddm="${4:-}"

if [[ -z "$ui_style" ]] && command -v jq >/dev/null 2>&1; then
  ui_style=$(jq -r '.themeStyle // "material3"' "$HOME/.config/quickshell/settings.json" 2>/dev/null || printf 'material3')
fi

fixed_terminal_assets="$script_dir/ensure-style-terminal-assets.sh"
if [[ -f "$fixed_terminal_assets" ]] &&
   ! bash "$fixed_terminal_assets"; then
  printf 'Fixed style terminal assets could not be prepared; keeping existing assets.\n' >&2
fi

if [[ "$ui_style" == "liquid-glass" ]]; then
  resolved_mode="$mode"
  if [[ "$resolved_mode" == "auto" ]]; then
    resolved_mode=$("$HOME/.local/bin/auto-detect-theme.sh" 2>/dev/null || printf 'auto')
  fi

  terminal_refresh="$script_dir/sync-active-palette.sh"
  if [[ ( "$resolved_mode" == "light" || "$resolved_mode" == "dark" ) &&
        -f "$HOME/.cache/matugen/current_palette.json" &&
        -f "$terminal_refresh" ]]; then
    if ! bash "$terminal_refresh" --terminal-only "$resolved_mode"; then
      printf 'Liquid Glass Matugen terminal refresh failed; keeping the existing terminal assets.\n' >&2
    fi
  fi

  # Keep the established desktop synchronizer responsible for the external
  # terminal, editor, monitor, compositor, and optional SDDM assets. Passing
  # Material 3 preserves the existing Matugen paths. MacTahoe then supplies
  # the Liquid Glass GTK/icon/Kvantum/cursor companion.
  fallback_args=("$mode" "$notify_mode" material3)
  [[ -n "$sync_sddm" ]] && fallback_args+=("$sync_sddm")
  "$HOME/.local/bin/sync-theme-mode.sh" "${fallback_args[@]}"
  bash "$script_dir/sync-mactahoe-theme.sh" "$resolved_mode"
  exit 0
fi

exec "$HOME/.local/bin/sync-theme-mode.sh" "$@"
