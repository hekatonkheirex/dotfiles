#!/bin/bash
MODE="$1"

{
  echo "=== $(date) START MODE=$MODE ==="
  
  notify-send -a "Theme Sync" "Setting mode: $MODE"

  apply_theme() {
    local theme="$1"
    local icon="${theme}-Icons"
    
    echo "Applying theme: $theme (icon: $icon)"
    
    gsettings set org.gnome.desktop.interface gtk-theme "$theme"
    gsettings set org.gnome.desktop.interface icon-theme "$icon"
    
    for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
      if [ -f "$ini" ]; then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$ini"
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon/" "$ini"
        echo "Updated $ini"
      fi
    done
    
    mkdir -p "$HOME/.config/gtk-4.0"
    rm -f "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
    rm -rf "$HOME/.config/gtk-4.0/assets"
    
    ln -s "$HOME/.themes/$theme/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
    ln -s "$HOME/.themes/$theme/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
    ln -s "$HOME/.themes/$theme/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
    echo "Created GTK4/Libadwaita symlinks to ~/.themes/$theme/gtk-4.0"
    
    if command -v kvantummanager &>/dev/null; then
      echo "Running kvantummanager --set $theme..."
      kvantummanager --set "$theme" && echo "kvantummanager OK" || echo "kvantummanager FAILED"
    fi
    
    local qt_style="kvantum"
    if [[ "$theme" == *"-Dark" ]]; then
      qt_style="kvantum-dark"
    fi
    local qt6conf="$HOME/.config/qt6ct/qt6ct.conf"
    if [ -f "$qt6conf" ]; then
      sed -i "s/^icon_theme=.*/icon_theme=$icon/" "$qt6conf"
      sed -i "s/^style=.*/style=$qt_style/" "$qt6conf"
      echo "Updated $qt6conf: icon_theme=$icon, style=$qt_style"
    fi
    
    killall nautilus 2>/dev/null && echo "killed nautilus" || echo "no nautilus"
    
    echo "Verifying: color-scheme=$(gsettings get org.gnome.desktop.interface color-scheme) gtk-theme=$(gsettings get org.gnome.desktop.interface gtk-theme)"
  }

  if [ "$MODE" = "auto" ]; then
    echo "Auto-detecting from wallpaper..."
    DETECTED=$("$HOME/.local/bin/auto-detect-theme.sh")
    echo "Detected: $DETECTED"
    if [ "$DETECTED" = "light" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'prefer-light'"
      apply_theme "Material3-Expressive-Dynamic"
      "$HOME/.local/bin/sync-terminal-theme.sh" "light"
    elif [ "$DETECTED" = "dark" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"
      apply_theme "Material3-Expressive-Dynamic-Dark"
      "$HOME/.local/bin/sync-terminal-theme.sh" "dark"
    else
      gsettings set org.gnome.desktop.interface color-scheme 'default'
      echo "Could not detect wallpaper, set color-scheme=default"
    fi
  elif [ "$MODE" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "'prefer-light'"
    apply_theme "Material3-Expressive-Dynamic"
    "$HOME/.local/bin/sync-terminal-theme.sh" "light"
  elif [ "$MODE" = "dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"
    apply_theme "Material3-Expressive-Dynamic-Dark"
    "$HOME/.local/bin/sync-terminal-theme.sh" "dark"
  fi
  
  echo "=== $(date) DONE ==="
} >> /tmp/sync-theme-mode.log 2>&1
