#!/bin/sh
# Apply an accent color: cache the matugen palette, regenerate themes, resync mode.
# Usage: apply-accent-color.sh RRGGBB
hex="$1"
[ -n "$hex" ] || { echo "usage: apply-accent-color.sh RRGGBB" >&2; exit 1; }

/usr/bin/matugen --json hex --type scheme-expressive color hex "#$hex" 2>/dev/null | python3 -c "
import json, sys, os
d = json.load(sys.stdin)['colors']
p = {'light': {t: m['light']['color'] for t, m in d.items()},
     'dark': {t: m['dark']['color'] for t, m in d.items()}}
os.makedirs(os.path.expanduser('~/.cache/matugen'), exist_ok=True)
json.dump({'scheme-expressive': p, '_seed': 'picker'},
          open(os.path.expanduser('~/.cache/matugen/current_palette.json'), 'w'))
" \
  && /usr/bin/matugen --type scheme-expressive color hex "#$hex" 2>/dev/null \
  && "$HOME/.local/bin/generate-all-themes.sh" \
  && "$HOME/.local/bin/sync-theme-mode.sh" auto
