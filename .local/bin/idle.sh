swayidle \
  timeout 150 'sh -c "if grep -q Discharging /sys/class/power_supply/BAT*/status; then brightnessctl set 30%; else brightnessctl set 100%; fi"' \
  resume 'brightnessctl set 100%' \
  timeout 300 'pidof gtklock || gtklock' \
  timeout 600 'wlopm --off' \
  resume 'wlopm --on' \
  timeout 900 'systemctl suspend'
