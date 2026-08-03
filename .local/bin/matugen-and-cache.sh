#!/bin/bash
IMG_PATH="$1"

# Capture JSON palette to cache so generators get fresh colors. Fidelity keeps
# the wallpaper's source hue instead of applying expressive hue rotations.
/usr/bin/matugen --json hex --type scheme-fidelity --prefer saturation image "$IMG_PATH" | \
  python3 -c "
import json, sys, os
data = json.load(sys.stdin)
raw = data['colors']
palette = {'light': {}, 'dark': {}}
for token, modes in raw.items():
    palette['light'][token] = modes['light']['color']
    palette['dark'][token] = modes['dark']['color']
cache = os.path.expanduser('~/.cache/matugen/current_palette.json')
os.makedirs(os.path.dirname(cache), exist_ok=True)
with open(cache, 'w') as f:
    json.dump({'scheme-expressive': palette, '_seed': 'wallpaper'}, f)
"

# Generate template (Colors.qml)
/usr/bin/matugen --type scheme-fidelity --prefer saturation image "$IMG_PATH"
