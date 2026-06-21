#!/bin/bash

# 1. Try the compositor-specific clean exits first
if [ "$XDG_CURRENT_DESKTOP" = "Niri" ] || [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
  niri msg action quit --skip-confirmation
fi

# 2. Give it a split second to breathe
sleep 0.5

# 3. If we are STILL in a session, force the issue.
# Instead of 'terminate', we 'kill' the session.
# This sends SIGTERM/SIGKILL to everything in that session ID immediately.
if [ -n "$XDG_SESSION_ID" ]; then
  loginctl kill-session "$XDG_SESSION_ID" --signal=SIGKILL
else
  loginctl kill-session self --signal=SIGKILL
fi
