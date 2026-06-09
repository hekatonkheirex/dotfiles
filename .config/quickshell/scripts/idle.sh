#!/usr/bin/env sh
if [ -n "$NIRI_SOCKET" ]; then
  dpms_off="niri msg action power-off-monitors"
  dpms_on="niri msg action power-on-monitors"
else
  dpms_off="/usr/bin/wlopm --off"
  dpms_on="/usr/bin/wlopm --on"
fi

exec setsid -f /usr/bin/swayidle \
  timeout 150 '/usr/bin/sh -c "if grep -q Discharging /sys/class/power_supply/BAT*/status; then /usr/bin/brightnessctl set 30%; else /usr/bin/brightnessctl set 100%; fi"' \
  resume '/usr/bin/sh -c "if grep -q Discharging /sys/class/power_supply/BAT*/status; then /usr/bin/brightnessctl set 30%; else /usr/bin/brightnessctl set 100%; fi"' \
  timeout 300 "$HOME/.config/quickshell/scripts/lock" \
  timeout 600 "eval $dpms_off" \
  resume "eval $dpms_on" \
  timeout 900 '/usr/bin/systemctl suspend' \
  >/dev/null 2>&1
