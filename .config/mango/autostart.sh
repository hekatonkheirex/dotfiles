#!/bin/bash

set +e

# obs
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots >/dev/null 2>&1

# notify
mako 2>&1 &

# night light
# wlsunset -T 3501 -t 3500 >/dev/null 2>&1 &

# wallpaper
swww-daemon 2>&1 &

# top bar
waybar -c ~/.config/mango/waybar/config.jsonc -s ~/.config/mango/waybar/style.css 2>&1 &

# xwayland dpi scale
echo "Xft.dpi: 140" | xrdb -merge #dpi缩放

# ime input
# fcitx5 --replace -d >/dev/null 2>&1 &

# keep clipboard content
wl-clip-persist --clipboard regular --reconnect-tries 0 >/dev/null 2>&1 &

# clipboard content manager
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
wl-paste --type image --watch cliphist store >/dev/null 2>&1 &

# bluetooth
blueman-applet >/dev/null 2>&1 &

# network
nm-applet >/dev/null 2>&1 &

# Permission authentication
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &

# inhibit by audio
hypridle 2>&1 &

# change light value and volume value by swayosd-client in keybind
swayosd-server >/dev/null 2>&1 &

gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2>&1 &

udiskie -2 2>&1 &

thunar --daemon 2>&1 &

enteauth 2>&1 &
