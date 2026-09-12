#!/usr/bin/env bash
set -euo pipefail

# 1. Try the compositor-specific clean exits first
if [ "$XDG_CURRENT_DESKTOP" = "Niri" ] || [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
  # SDDM does not reliably recreate its greeter after niri-session exits with
  # the helper's termination status. Ask it to prepare/activate a greeter
  # while this session is still alive; busctl waits for SDDM's reply.
  busctl --system call \
    org.freedesktop.DisplayManager \
    /org/freedesktop/DisplayManager/Seat0 \
    org.freedesktop.DisplayManager.Seat \
    SwitchToGreeter >/dev/null 2>&1 || true

  # A successful IPC request already asks Niri to end the session. Starting a
  # second logind teardown here races with Niri's shutdown and can leave SDDM
  # with a blank VT instead of a usable greeter.
  if niri msg action quit --skip-confirmation; then
    exit 0
  fi
fi

# Mango exposes the same clean exit through its IPC socket.
if [ "$XDG_CURRENT_DESKTOP" = "Mango" ] || [ "$XDG_CURRENT_DESKTOP" = "mango" ]; then
  if mmsg dispatch quit >/dev/null 2>&1; then
    exit 0
  fi
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
