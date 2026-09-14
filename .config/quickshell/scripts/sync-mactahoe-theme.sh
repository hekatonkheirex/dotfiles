#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=theme-sync-lock.sh
source "$script_dir/theme-sync-lock.sh"

mode="${1:-auto}"
if [[ "$mode" == "auto" ]]; then
  mode=$("$HOME/.local/bin/auto-detect-theme.sh" 2>/dev/null || printf 'auto')
fi

if [[ "$mode" != "light" && "$mode" != "dark" ]]; then
  printf 'MacTahoe sync skipped: could not resolve a light/dark mode (got %s).\n' "$mode"
  exit 0
fi

gtk_theme="MacTahoe-Light"
icon_theme="MacTahoe-light"
qt_theme="MacTahoe"
qt_style="kvantum"
gtk_prefer_dark=0
if [[ "$mode" == "dark" ]]; then
  gtk_theme="MacTahoe-Dark"
  icon_theme="MacTahoe-dark"
  qt_theme="MacTahoeDark"
  qt_style="kvantum-dark"
  gtk_prefer_dark=1
fi

cursor_theme="MacTahoe-cursors"
if [[ "$mode" == "dark" ]]; then
  cursor_theme="MacTahoe-dark-cursors"
fi

cursor_theme_dir=""
for candidate in \
  "$HOME/.local/share/icons/$cursor_theme" \
  "$HOME/.icons/$cursor_theme"; do
  if [[ -f "$candidate/index.theme" ]]; then
    cursor_theme_dir="$candidate"
    break
  fi
done

gtk_theme_dir="$HOME/.themes/$gtk_theme"
if [[ ! -f "$gtk_theme_dir/index.theme" ||
      ! -f "$gtk_theme_dir/gtk-3.0/gtk.css" ||
      ! -f "$gtk_theme_dir/gtk-4.0/gtk.css" ]]; then
  printf 'MacTahoe GTK theme not found for %s at %s; keeping the existing GTK theme.\n' \
    "$mode" "$gtk_theme_dir"
  exit 0
fi

icon_theme_dir=""
for candidate in \
  "$HOME/.local/share/icons/$icon_theme" \
  "$HOME/.icons/$icon_theme"; do
  if [[ -f "$candidate/index.theme" ]]; then
    icon_theme_dir="$candidate"
    break
  fi
done

set_ini_value() {
  local file=$1
  local key=$2
  local value=$3

  if rg -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  fi
}

for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
  [[ -f "$ini" ]] || continue
  set_ini_value "$ini" gtk-theme-name "$gtk_theme"
  if [[ -n "$icon_theme_dir" ]]; then
    set_ini_value "$ini" gtk-icon-theme-name "$icon_theme"
  fi
  if [[ -n "$cursor_theme_dir" ]]; then
    set_ini_value "$ini" gtk-cursor-theme-name "$cursor_theme"
  fi
  set_ini_value "$ini" gtk-application-prefer-dark-theme "$gtk_prefer_dark"
done

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" ||
    printf 'Could not set the GTK theme through gsettings.\n' >&2
  if [[ -n "$icon_theme_dir" ]]; then
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" ||
      printf 'Could not set the MacTahoe icon theme through gsettings.\n' >&2
  else
    printf 'MacTahoe icon theme not found for %s; keeping the existing icon theme.\n' "$mode"
  fi
  if [[ -n "$cursor_theme_dir" ]]; then
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" ||
      printf 'Could not set the MacTahoe cursor theme through gsettings.\n' >&2
  else
    printf 'MacTahoe cursor theme not found for %s; keeping the existing cursor theme.\n' "$mode" >&2
  fi
  gsettings set org.gnome.desktop.interface color-scheme "'prefer-$mode'" ||
    printf 'Could not set the GTK color scheme to prefer-%s.\n' "$mode" >&2
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
kvantum_dir="$config_home/Kvantum/MacTahoe"
kvantum_theme_file="$kvantum_dir/$qt_theme.kvconfig"
kvantum_svg_file="$kvantum_dir/$qt_theme.svg"
kvantum_state_file="$config_home/Kvantum/kvantum.kvconfig"

if [[ ! -f "$kvantum_theme_file" || ! -f "$kvantum_svg_file" ]]; then
  printf 'MacTahoe Kvantum theme not found for %s at %s; keeping the existing Qt theme.\n' \
    "$mode" "$kvantum_dir/$qt_theme"
else
  kvantum_set=0
  if command -v kvantummanager >/dev/null 2>&1 && kvantummanager --set "$qt_theme" >/dev/null 2>&1; then
    kvantum_set=1
  fi

  # The manager is the normal owner of this selection. Keep a small fallback
  # for installations where the manager cannot discover a theme stored beside
  # another variant in the same directory, as MacTahoe does.
  if [[ -f "$kvantum_state_file" && "$kvantum_set" -eq 0 ]]; then
    if rg -q '^theme=' "$kvantum_state_file"; then
      sed -i "s|^theme=.*|theme=$qt_theme|" "$kvantum_state_file"
      kvantum_set=1
    fi
  fi

  if [[ "$kvantum_set" -eq 1 && -f "$kvantum_state_file" &&
        "$(sed -n 's/^theme=//p' "$kvantum_state_file" | head -n 1)" == "$qt_theme" ]]; then
    printf 'MacTahoe Kvantum sync -> theme=%s\n' "$qt_theme"
  else
    printf 'Could not select the MacTahoe Kvantum theme: %s\n' "$qt_theme" >&2
  fi

  qt6ct_config="$config_home/qt6ct/qt6ct.conf"
  if [[ -f "$qt6ct_config" ]]; then
    set_ini_value "$qt6ct_config" icon_theme "$icon_theme"
    set_ini_value "$qt6ct_config" style "$qt_style"
    printf 'Updated %s: style=%s, icon_theme=%s\n' \
      "$qt6ct_config" "$qt_style" "$icon_theme"
  fi
fi

gtk4_config_dir="$HOME/.config/gtk-4.0"
mkdir -p -- "$gtk4_config_dir"

link_gtk4_asset() {
  local asset=$1
  local source="$gtk_theme_dir/gtk-4.0/$asset"
  local target="$gtk4_config_dir/$asset"

  if [[ ! -e "$source" ]]; then
    printf 'MacTahoe GTK4 asset is missing: %s\n' "$source" >&2
    return 1
  fi

  if [[ -L "$target" ]]; then
    rm -f -- "$target"
  elif [[ -e "$target" ]]; then
    printf 'Leaving existing GTK4 %s because it is not a symlink: %s\n' "$asset" "$target" >&2
    return 0
  fi
  ln -s -- "$source" "$target"
}

link_gtk4_asset gtk.css
link_gtk4_asset gtk-dark.css
link_gtk4_asset assets

set_cursor_theme_value() {
  local file=$1
  [[ -f "$file" ]] || return 0
  if rg -q '^cursor_theme=' "$file"; then
    sed -i "s|^cursor_theme=.*|cursor_theme=$cursor_theme|" "$file"
  fi
}

if [[ -n "$cursor_theme_dir" ]]; then
  # sync-terminal-theme.sh regenerates Mango's fragment before this script
  # runs, so apply the MacTahoe cursor after that fallback has selected its
  # default Bibata value. decorations.conf is hand-maintained but owns the
  # same Mango-wide cursor setting and must stay consistent too.
  set_cursor_theme_value "$HOME/.config/mango/theme.conf"
  set_cursor_theme_value "$HOME/.config/mango/decorations.conf"

  desktop_name="$(printenv XDG_CURRENT_DESKTOP 2>/dev/null || true)"
  if [[ -z "$desktop_name" ]]; then
    desktop_name="$(printenv XDG_SESSION_DESKTOP 2>/dev/null || true)"
  fi
  desktop_lower="$(printf '%s' "$desktop_name" | tr '[:upper:]' '[:lower:]')"
  case "$desktop_lower" in
    mango*)
      if command -v mmsg >/dev/null 2>&1 && ! mmsg dispatch reload_config >/dev/null 2>&1; then
        printf 'Could not reload Mango after applying the MacTahoe cursor theme.\n' >&2
      fi
      ;;
  esac
fi

cursor_display="${cursor_theme_dir:+$cursor_theme}"
[[ -n "$cursor_display" ]] || cursor_display=existing
printf 'MacTahoe GTK/icon/Qt/cursor sync -> mode=%s gtk=%s icons=%s qt=%s cursor=%s\n' \
  "$mode" "$gtk_theme" "${icon_theme_dir:-existing}" "$qt_theme" "$cursor_display"
