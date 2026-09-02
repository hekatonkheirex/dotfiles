#!/usr/bin/env bash
set -euo pipefail

# 1. Try the compositor-specific clean exits first
if [ "$XDG_CURRENT_DESKTOP" = "Niri" ] || [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
  niri msg action quit --skip-confirmation || true
fi

# 2. Ask logind to terminate the session gracefully and give applications time
# to save state and stop their user services.
session_id="${XDG_SESSION_ID:-self}"
if ! loginctl show-session "$session_id" >/dev/null 2>&1; then
  exit 0
fi
loginctl terminate-session "$session_id" >/dev/null 2>&1 || true

# 3. Keep a bounded emergency fallback for a stuck session.
for _ in {1..20}; do
  if ! loginctl show-session "$session_id" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.25
done

loginctl kill-session "$session_id" --signal=SIGKILL
