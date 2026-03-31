#!/bin/bash

# 1. Try the compositor-specific clean exits first
if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
  hyprctl dispatch exit
elif [ "$XDG_CURRENT_DESKTOP" = "labwc" ] || [ "$XDG_CURRENT_DESKTOP" = "mangoWC" ]; then
  # labwc (which mangoWC uses) responds to SIGHUP or its own exit command
  labwc --exit
fi

# 2. Give it a split second to breathe
sleep 0.5

# 3. If we are STILL in a session, force the issue.
# Instead of 'terminate', we 'kill' the session.
# This sends SIGTERM/SIGKILL to everything in that session ID immediately.
loginctl kill-session self --signal=SIGKILL
