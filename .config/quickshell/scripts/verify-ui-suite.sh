#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
skip_sddm=0

usage() {
  cat <<'EOF'
Usage: verify-ui-suite.sh [options]

Verify the palette-driven GTK, icon, Kvantum and terminal companions.
SDDM is checked through its existing system integration verifier unless
--skip-sddm is supplied.

Options:
  --skip-sddm    Skip system-wide SDDM checks
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-sddm)
      skip_sddm=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

failures=0
pass_check() {
  printf 'OK   %s\n' "$1"
}
fail_check() {
  printf 'FAIL %s\n' "$1" >&2
  failures=$((failures + 1))
}

check_file() {
  local path=$1
  local label=${2:-$path}
  if [[ -f "$path" ]]; then
    pass_check "$label"
  else
    fail_check "$label ($path)"
  fi
}


check_gtk_theme() {
  local theme=$1
  local theme_dir="$HOME/.themes/$theme"
  check_file "$theme_dir/index.theme" "$theme GTK metadata"
  check_file "$theme_dir/gtk-3.0/gtk.css" "$theme GTK 3 stylesheet"
  check_file "$theme_dir/gtk-4.0/gtk.css" "$theme GTK 4 stylesheet"
}

check_icon_theme() {
  local theme=$1
  local theme_dir=""
  if [[ -f "$HOME/.local/share/icons/$theme/index.theme" ]]; then
    theme_dir="$HOME/.local/share/icons/$theme"
  elif [[ -f "$HOME/.icons/$theme/index.theme" ]]; then
    theme_dir="$HOME/.icons/$theme"
  fi
  if [[ -n "$theme_dir" ]]; then
    pass_check "$theme icon metadata"
  else
    fail_check "$theme icon metadata"
  fi
}

check_kvantum_theme() {
  local theme=$1
  check_file "$HOME/.config/Kvantum/$theme/$theme.kvconfig" "$theme Kvantum config"
  check_file "$HOME/.config/Kvantum/$theme/$theme.svg" "$theme Kvantum SVG"
}


for theme in Material3-Expressive-Dynamic Material3-Expressive-Dynamic-Dark; do
  check_gtk_theme "$theme"
done

for theme in Material3-Expressive-Dynamic-Icons Material3-Expressive-Dynamic-Dark-Icons; do
  check_icon_theme "$theme"
done

for theme in Material3-Expressive-Dynamic Material3-Expressive-Dynamic-Dark; do
  check_kvantum_theme "$theme"
done


for file in \
  "$HOME/.config/kitty/matugen-light.conf" \
  "$HOME/.config/kitty/matugen-dark.conf"; do
  check_file "$file" "Kitty style asset $(basename "$file")"
done

for file in \
  "$HOME/.config/starship/matugen-light.toml" \
  "$HOME/.config/starship/matugen-dark.toml"; do
  check_file "$file" "Starship style asset $(basename "$file")"
done

if (( ! skip_sddm )); then
  bash "$script_dir/verify-sddm-integration.sh"
else
  printf 'SKIP SDDM checks (--skip-sddm)\n'
fi

if (( failures > 0 )); then
  printf '\nUI suite verification failed (%d check(s)).\n' "$failures" >&2
  exit 1
fi

printf '\nUI suite verification passed.\n'
