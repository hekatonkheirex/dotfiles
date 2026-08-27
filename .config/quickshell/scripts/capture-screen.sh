#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
case "$mode" in
  screen|region) ;;
  *)
    notify-send -a Quickshell -u critical "Capture unavailable" \
      "Choose a full-screen or region capture."
    exit 2
    ;;
esac

if ! command -v grim >/dev/null 2>&1 || ! command -v notify-send >/dev/null 2>&1; then
  exit 127
fi

output_dir="${HOME}/Pictures/Screenshots"
mkdir -p "$output_dir"

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
output_file="${output_dir}/Screenshot_${timestamp}.png"
suffix=1
while [[ -e "$output_file" ]]; do
  output_file="${output_dir}/Screenshot_${timestamp}_${suffix}.png"
  suffix=$((suffix + 1))
done

if [[ "$mode" == "region" ]]; then
  if ! command -v slurp >/dev/null 2>&1; then
    notify-send -a Quickshell -u critical "Capture unavailable" \
      "The region selector (slurp) is not installed."
    exit 127
  fi

  geometry="$(slurp 2>/dev/null || true)"
  # Cancelling the selector is a normal interaction, not an error.
  if [[ -z "$geometry" ]]; then
    exit 0
  fi

  grim -g "$geometry" "$output_file"
else
  grim "$output_file"
fi

clipboard_note=""
if command -v wl-copy >/dev/null 2>&1 && wl-copy < "$output_file" 2>/dev/null; then
  clipboard_note=" and copied to the clipboard"
fi

notify-send -a Quickshell "Screenshot saved" \
  "${output_file}${clipboard_note}"
