#!/usr/bin/env bash
# Gate test: bash tests/wallpaper-filmstrip/random.test.sh
set -euo pipefail
here=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
script="$here/../../scripts/random-wallpaper.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmp/walls"
for n in a.jpg b.png c.webp "d e.jpeg"; do : > "$tmp/walls/$n"; done
: > "$tmp/walls/notes.txt"
cat > "$tmp/apply" <<'S'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$OUT"
S
chmod +x "$tmp/apply"
export WALLS_DIR="$tmp/walls" APPLY_CMD="$tmp/apply" OUT="$tmp/out"

# Only image files, never the current wallpaper, and over many runs every other one shows up.
: > "$OUT"
for _ in $(seq 1 120); do CURRENT_WALLPAPER="a.jpg" bash "$script"; done
! grep -qx "a.jpg" "$OUT" || fail "picked the current wallpaper"
! grep -q "notes.txt" "$OUT" || fail "picked a non-image"
for n in b.png c.webp "d e.jpeg"; do grep -qxF "$n" "$OUT" || fail "never picked $n"; done

# A single wallpaper is applied even though it is the current one.
rm "$tmp/walls/b.png" "$tmp/walls/c.webp" "$tmp/walls/d e.jpeg"
: > "$OUT"
CURRENT_WALLPAPER="a.jpg" bash "$script"
[[ $(cat "$OUT") == "a.jpg" ]] || fail "single wallpaper not applied"

# An empty folder is an error, not a silent no-op.
rm "$tmp/walls/a.jpg"
if CURRENT_WALLPAPER="" bash "$script" 2>/dev/null; then fail "empty folder should fail"; fi
echo "PASS random"
