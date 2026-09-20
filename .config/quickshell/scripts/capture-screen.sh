#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
case "$mode" in
  screen|monitor|region|confirm|cancel) ;;
  *)
    notify-send -a Quickshell -u critical "Capture unavailable" \
      "Choose a monitor or region capture."
    exit 2
    ;;
esac

if ! command -v grim >/dev/null 2>&1 || ! command -v notify-send >/dev/null 2>&1; then
  exit 127
fi

output_dir="${HOME}/Pictures/Screenshots"
state_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
state_file="${state_dir}/mango-screenshot-region-${UID:-$(id -u)}"
selection_notification_file="${state_file}.notification"

is_mango_session() {
  [[ -n "${MANGO_INSTANCE_SIGNATURE:-}" ]] && command -v mmsg >/dev/null 2>&1
}

set_mango_keymode() {
  is_mango_session || return 1
  mmsg dispatch "setkeymode,$1" >/dev/null 2>&1
}

reset_mango_keymode() {
  if is_mango_session; then
    mmsg dispatch setkeymode,default >/dev/null 2>&1 || true
  fi
}

close_selection_cue() {
  local notification_id
  notification_id="$(cat "$selection_notification_file" 2>/dev/null || true)"
  rm -f "$selection_notification_file"

  if [[ "$notification_id" =~ ^[0-9]+$ ]] && command -v gdbus >/dev/null 2>&1; then
    gdbus call --session \
      --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.CloseNotification \
      "$notification_id" >/dev/null 2>&1 || true
  fi
}

show_selection_cue() {
  local notification_id state_tmp
  notification_id="$(notify-send -a Quickshell -u normal -t 0 -p \
    "Screenshot region ready" \
    "Press Enter or Space to capture; Esc to cancel." 2>/dev/null || true)"
  if [[ ! "$notification_id" =~ ^[0-9]+$ ]]; then
    return 0
  fi

  state_tmp="$(mktemp "${selection_notification_file}.XXXXXX")"
  chmod 600 "$state_tmp"
  printf '%s\n' "$notification_id" > "$state_tmp"
  mv -f "$state_tmp" "$selection_notification_file"
}

dismiss_quickshell_popups() {
  if command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call shell dismissPopups >/dev/null 2>&1 || true
  fi
}

new_output_file() {
  mkdir -p "$output_dir"

  local timestamp suffix
  timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
  output_file="${output_dir}/Screenshot_${timestamp}.png"
  suffix=1
  while [[ -e "$output_file" ]]; do
    output_file="${output_dir}/Screenshot_${timestamp}_${suffix}.png"
    suffix=$((suffix + 1))
  done
}

finish_capture() {
  local clipboard_note=""
  if command -v wl-copy >/dev/null 2>&1 \
    && wl-copy --type image/png < "$output_file" 2>/dev/null; then
    clipboard_note=" and copied to the clipboard"
  fi

  notify-send -a Quickshell "Screenshot saved" \
    "${output_file}${clipboard_note}"
}

capture_region() {
  local geometry="$1"
  new_output_file
  grim -g "$geometry" "$output_file"
  finish_capture
}

capture_desktop() {
  dismiss_quickshell_popups
  new_output_file
  grim "$output_file"
  finish_capture
}

capture_monitor() {
  if ! command -v mmsg >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    notify-send -a Quickshell -u critical "Capture unavailable" \
      "Mango monitor discovery requires mmsg and jq."
    return 127
  fi

  dismiss_quickshell_popups

  local monitor
  monitor="$(mmsg get all-monitors 2>/dev/null \
    | jq -r '[.monitors[]? | select(.active == true) | .name][0] // empty' \
    2>/dev/null || true)"
  if [[ -z "$monitor" ]]; then
    notify-send -a Quickshell -u critical "Capture unavailable" \
      "Could not determine Mango's focused monitor."
    return 1
  fi

  new_output_file
  grim -o "$monitor" "$output_file"
  finish_capture
}

begin_region() {
  if ! command -v slurp >/dev/null 2>&1; then
    notify-send -a Quickshell -u critical "Capture unavailable" \
      "The region selector (slurp) is not installed."
    return 127
  fi

  dismiss_quickshell_popups
  close_selection_cue
  rm -f "$state_file"

  local geometry
  geometry="$(slurp -b '#00000088' 2>/dev/null || true)"
  # Cancelling the selector is a normal interaction, not an error.
  if [[ -z "$geometry" ]]; then
    return 0
  fi

  # Mango's transient key mode provides the same explicit confirmation step
  # as Niri's screenshot UI. Other compositors keep the original immediate
  # slurp -> grim behavior used by the Quickshell launcher.
  if is_mango_session; then
    local state_tmp
    state_tmp="$(mktemp "${state_file}.XXXXXX")"
    chmod 600 "$state_tmp"
    printf '%s\n' "$geometry" > "$state_tmp"
    mv -f "$state_tmp" "$state_file"

    if set_mango_keymode screenshot-confirm; then
      show_selection_cue
      return 0
    fi

    rm -f "$state_file"
  fi

  capture_region "$geometry"
}

confirm_region() {
  local geometry
  geometry="$(cat "$state_file" 2>/dev/null || true)"
  close_selection_cue
  rm -f "$state_file"
  reset_mango_keymode

  [[ -n "$geometry" ]] || return 0
  capture_region "$geometry"
}

cancel_region() {
  close_selection_cue
  rm -f "$state_file"
  reset_mango_keymode
}

case "$mode" in
  region)
    begin_region
    ;;
  confirm)
    confirm_region
    ;;
  cancel)
    cancel_region
    ;;
  monitor)
    capture_monitor
    ;;
  screen)
    capture_desktop
    ;;
esac
