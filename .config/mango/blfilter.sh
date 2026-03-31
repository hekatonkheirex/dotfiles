#!/bin/sh
# Fetch location based on IP
CONTENT=$(curl -s http://ip-api.com/json/)

# Parse coordinates (requires 'jq' to be installed)
LAT=$(echo $CONTENT | jq .lat)
LON=$(echo $CONTENT | jq .lon)

# Start wlsunset with dynamic coordinates
# -t 3500 (Night temp) -T 6500 (Day temp)
wlsunset -l $LAT -L $LON -t 3500 -T 5500 &
