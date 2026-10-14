#!/bin/bash
set -euo pipefail

# Keep direct invocations serialized with Quickshell's palette pipeline. When
# this script is called from an already locked refresh, the sourced helper
# reuses that lock instead of deadlocking nested generator calls.
source "$HOME/.config/quickshell/scripts/theme-sync-lock.sh"

theme_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
umask 077
mkdir -p -- "$theme_state_dir"

MODE="${1:-auto}"
NOTIFY_MODE="${2:-}"
# $3 (UI style) is accepted for old callers and ignored: the shell has one
# style, so the SDDM synchronizer always receives "material3".
SYNC_SDDM="${4:-}"

{
  echo "=== $(date) START MODE=$MODE ==="
  
  if [[ "$NOTIFY_MODE" != "--quiet" ]]; then
    notify-send -a "Theme Sync" "Setting mode: $MODE"
  fi

  apply_theme() {
    local gtk_theme="$1"
    local icon_theme="$2"
    local qt_theme="$3"
    local gtk_font="$4"
    local qt_fixed_font="$5"
    local qt_general_font="$6"
    local qt_style="kvantum"
    if [[ "$qt_theme" == *"-Dark" ]]; then
      qt_style="kvantum-dark"
    fi
    
    echo "Applying GTK theme: $gtk_theme (icon: $icon_theme, Qt: $qt_theme)"
    
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
    gsettings set org.gnome.desktop.interface font-name "$gtk_font"
    
    for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
      if [ -f "$ini" ]; then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$ini"
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$ini"
        sed -i "s/^gtk-font-name=.*/gtk-font-name=$gtk_font/" "$ini"
        echo "Updated $ini"
      fi
    done
    
    mkdir -p "$HOME/.config/gtk-4.0"
    rm -f "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
    rm -rf "$HOME/.config/gtk-4.0/assets"
    
    ln -s "$HOME/.themes/$gtk_theme/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
    ln -s "$HOME/.themes/$gtk_theme/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
    ln -s "$HOME/.themes/$gtk_theme/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
    echo "Created GTK4/Libadwaita symlinks to ~/.themes/$gtk_theme/gtk-4.0"
    
    if command -v kvantummanager &>/dev/null; then
      echo "Running kvantummanager --set $qt_theme..."
      kvantummanager --set "$qt_theme" && echo "kvantummanager OK" || echo "kvantummanager FAILED"
    fi

    local qt6conf="$HOME/.config/qt6ct/qt6ct.conf"
    if [ -f "$qt6conf" ]; then
      sed -i "s/^icon_theme=.*/icon_theme=$icon_theme/" "$qt6conf"
      sed -i "s/^style=.*/style=$qt_style/" "$qt6conf"
      sed -i "s|^fixed=.*|fixed=\"$qt_fixed_font\"|" "$qt6conf"
      sed -i "s|^general=.*|general=\"$qt_general_font\"|" "$qt6conf"
      echo "Updated $qt6conf: icon_theme=$icon_theme, style=$qt_style, fonts=$qt_general_font / $qt_fixed_font"
    fi
    
    killall nautilus 2>/dev/null && echo "killed nautilus" || echo "no nautilus"
    
    echo "Verifying: color-scheme=$(gsettings get org.gnome.desktop.interface color-scheme) gtk-theme=$(gsettings get org.gnome.desktop.interface gtk-theme)"
  }

  sync_mode() {
    local mode="$1"
    local gtk_theme="Material3-Expressive-Dynamic"
    local icon_theme="Material3-Expressive-Dynamic-Icons"
    local qt_theme="Material3-Expressive-Dynamic"
    local gtk_font="Roboto Flex 13"
    local qt_fixed_font="Google Sans Code,14,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"
    local qt_general_font="Roboto Flex,13,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"

    if [ "$mode" = "dark" ]; then
      gtk_theme="Material3-Expressive-Dynamic-Dark"
      icon_theme="Material3-Expressive-Dynamic-Dark-Icons"
      qt_theme="Material3-Expressive-Dynamic-Dark"
    fi

    apply_theme "$gtk_theme" "$icon_theme" "$qt_theme" "$gtk_font" "$qt_fixed_font" "$qt_general_font"
    "$HOME/.local/bin/sync-terminal-theme.sh" "$mode" ""
    if [ "$SYNC_SDDM" = "--sync-sddm" ]; then
      "$HOME/.local/bin/sync-sddm-theme.sh" "$mode" "material3" \
        && echo "SDDM theme synchronized" \
        || echo "SDDM theme synchronization failed; current session remains unchanged"
    fi
  }

  if [ "$MODE" = "auto" ]; then
    echo "Auto-detecting from wallpaper..."
    DETECTED=$("$HOME/.local/bin/auto-detect-theme.sh")
    echo "Detected: $DETECTED"
    if [ "$DETECTED" = "light" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'prefer-light'"
      sync_mode "light"
    elif [ "$DETECTED" = "dark" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"
      sync_mode "dark"
    else
      gsettings set org.gnome.desktop.interface color-scheme 'default'
      echo "Could not detect wallpaper, set color-scheme=default"
    fi
  elif [ "$MODE" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "'prefer-light'"
    sync_mode "light"
  elif [ "$MODE" = "dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"
    sync_mode "dark"
  fi
  
  echo "=== $(date) DONE ==="
} >>"$theme_state_dir/sync-theme-mode.log" 2>&1
