#!/bin/bash
MODE="${1:-auto}"
NOTIFY_MODE="${2:-}"
UI_STYLE="${3:-}"
SYNC_SDDM="${4:-}"

if [ -z "$UI_STYLE" ] && command -v jq &>/dev/null; then
  UI_STYLE=$(jq -r '.themeStyle // "material3"' "$HOME/.config/quickshell/settings.json" 2>/dev/null || echo material3)
fi
case "$UI_STYLE" in
  nothing|neo-brutalism|material3) ;;
  *) UI_STYLE=material3 ;;
esac

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

    if [ "$UI_STYLE" = "nothing" ]; then
      local nothing_theme="Nothing-OS"
      local nothing_icon_theme="Nothing-Light-Icons"
      [ "$mode" = "dark" ] && nothing_theme="Nothing-OS-Dark"
      [ "$mode" = "dark" ] && nothing_icon_theme="Nothing-Dark-Icons"
      if [ -d "$HOME/.themes/$nothing_theme/gtk-4.0" ]; then
        gtk_theme="$nothing_theme"
        gtk_font="NType 82 13"
      else
        echo "Nothing GTK theme not found at ~/.themes/$nothing_theme; keeping Material 3 GTK."
      fi
      if [ -f "$HOME/.local/share/icons/$nothing_icon_theme/index.theme" ] || \
        [ -f "$HOME/.icons/$nothing_icon_theme/index.theme" ]; then
        icon_theme="$nothing_icon_theme"
      else
        echo "Nothing icon theme not found at ~/.local/share/icons/$nothing_icon_theme or ~/.icons/$nothing_icon_theme; keeping Material 3 icons."
      fi
      qt_theme="$nothing_theme"
      qt_fixed_font="NType 82 Mono,14,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"
      qt_general_font="NType 82,13,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"
    fi

    if [ "$UI_STYLE" = "neo-brutalism" ]; then
      local neo_theme="Neo-Brutalism"
      local neo_icon_theme="Neo-Brutalism-Icons"
      [ "$mode" = "dark" ] && neo_theme="Neo-Brutalism-Dark"
      [ "$mode" = "dark" ] && neo_icon_theme="Neo-Brutalism-Dark-Icons"
      if [ -d "$HOME/.themes/$neo_theme/gtk-4.0" ]; then
        gtk_theme="$neo_theme"
        gtk_font="JetBrains Mono 13"
      else
        echo "Neo Brutalism GTK theme not found at ~/.themes/$neo_theme; keeping Material 3 GTK."
      fi
      if [ -f "$HOME/.config/Kvantum/$neo_theme/$neo_theme.kvconfig" ]; then
        qt_theme="$neo_theme"
      else
        echo "Neo Brutalism Kvantum theme not found at ~/.config/Kvantum/$neo_theme; keeping Material 3 Qt style."
      fi
      if [ -f "$HOME/.local/share/icons/$neo_icon_theme/index.theme" ] || \
        [ -f "$HOME/.icons/$neo_icon_theme/index.theme" ]; then
        icon_theme="$neo_icon_theme"
      else
        echo "Neo Brutalism icon theme not found at ~/.local/share/icons/$neo_icon_theme or ~/.icons/$neo_icon_theme; keeping Material 3 icons."
      fi
      qt_fixed_font="JetBrains Mono,14,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"
      qt_general_font="JetBrains Mono,13,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"
    fi

    apply_theme "$gtk_theme" "$icon_theme" "$qt_theme" "$gtk_font" "$qt_fixed_font" "$qt_general_font"
    "$HOME/.local/bin/sync-terminal-theme.sh" "$mode" "" "$UI_STYLE"
    if [ "$SYNC_SDDM" = "--sync-sddm" ]; then
      "$HOME/.local/bin/sync-sddm-theme.sh" "$mode" "$UI_STYLE" \
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
} >> /tmp/sync-theme-mode.log 2>&1
