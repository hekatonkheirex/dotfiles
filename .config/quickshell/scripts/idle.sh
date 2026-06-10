#!/usr/bin/env sh
if [ -n "$NIRI_SOCKET" ]; then
  dpms_off="niri msg action power-off-monitors"
  dpms_on="niri msg action power-on-monitors"
else
  dpms_off="/usr/bin/wlopm --off"
  dpms_on="/usr/bin/wlopm --on"
fi

exec setsid -f /usr/bin/swayidle \
  timeout 150 '/usr/bin/sh -c "brightnessctl g > /tmp/qs-prev-brightness && brightnessctl set 10%"' \
  resume '/usr/bin/sh -c "brightnessctl set $(cat /tmp/qs-prev-brightness 2>/dev/null || echo 100%)"' \
  timeout 300 "$HOME/.config/quickshell/scripts/lock" \
  timeout 600 "eval $dpms_off" \
  resume "eval $dpms_on" \
  timeout 900 '/usr/bin/systemctl suspend' \
  >/dev/null 2>&1
