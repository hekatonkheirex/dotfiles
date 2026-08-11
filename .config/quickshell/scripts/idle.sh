#!/usr/bin/env sh

settings_file="$HOME/.config/quickshell/settings.json"

read_timeout() {
  key="$1"
  fallback="$2"
  maximum="$3"
  value=""

  if [ -r "$settings_file" ] && command -v jq >/dev/null 2>&1; then
    value=$(jq -r --arg key "$key" '.[$key] // empty' "$settings_file" 2>/dev/null)
  fi

  case "$value" in
    ''|*[!0-9]*)
      printf '%s' "$fallback"
      ;;
    *)
      if [ "$value" -le "$maximum" ]; then
        printf '%s' "$value"
      else
        printf '%s' "$fallback"
      fi
      ;;
  esac
}

# Settings changes restart the current idle watcher without defeating Caffeine.
# If swayidle is not running, keep it stopped until the user disables Caffeine.
if [ "${1:-}" = "restart" ]; then
  if ! /usr/bin/pgrep -x swayidle >/dev/null 2>&1; then
    exit 0
  fi
  /usr/bin/pkill -x swayidle >/dev/null 2>&1 || true
fi

lock_timeout=$(read_timeout idleLockTimeoutSeconds 300 86400)
suspend_timeout=$(read_timeout idleSuspendTimeoutSeconds 900 86400)

if [ -n "$NIRI_SOCKET" ]; then
  dpms_off="niri msg action power-off-monitors"
  dpms_on="niri msg action power-on-monitors"
else
  dpms_off="/usr/bin/wlopm --off"
  dpms_on="/usr/bin/wlopm --on"
fi

set -- /usr/bin/swayidle \
  timeout 150 '/usr/bin/sh -c "brightnessctl g > /tmp/qs-prev-brightness && brightnessctl set 10%"' \
  resume '/usr/bin/sh -c "brightnessctl set $(cat /tmp/qs-prev-brightness 2>/dev/null || echo 100%)"'

if [ "$lock_timeout" -gt 0 ]; then
  set -- "$@" timeout "$lock_timeout" "$HOME/.config/quickshell/scripts/lock"
fi

set -- "$@" \
  timeout 600 "eval $dpms_off" \
  resume "eval $dpms_on"

if [ "$suspend_timeout" -gt 0 ]; then
  suspend_command="\"$HOME/.config/quickshell/scripts/lock\" && /usr/bin/systemctl suspend"
  set -- "$@" timeout "$suspend_timeout" "$suspend_command"
fi

exec setsid -f "$@" >/dev/null 2>&1
