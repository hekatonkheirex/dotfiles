#!/usr/bin/env bash
# Restarts quickshell.service when its Qt scenegraph loses the GPU context
# (i915 GPU hang -> QRhiGles2 context lost) and never recovers on its own.
set -euo pipefail

# Both "Context is lost" and "Graphics device lost" fire for the same event;
# debounce so one hang triggers exactly one restart.
last_restart=0
journalctl --user -u quickshell.service -f -n0 -o cat |
  grep --line-buffered -E "Graphics device lost|Context is lost" |
  while read -r _; do
    now=$(date +%s)
    if (( now - last_restart < 5 )); then
      continue
    fi
    last_restart=$now
    logger -t gpu-hang-watchdog "quickshell GPU context lost, restarting service"
    systemctl --user restart quickshell.service
  done
