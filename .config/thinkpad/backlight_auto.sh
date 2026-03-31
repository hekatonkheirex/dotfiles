#!/bin/bash
# Logic: Set brightness based on power supply status
# ATTR{online} == 1 is AC, 0 is Battery

if [ "$1" = "ac" ]; then
    brightnessctl set 100%
else
    brightnessctl set 30%
fi
