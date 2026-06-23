#!/usr/bin/env python3
import sys
import dbus

def get_active_player(bus):
    players = []
    try:
        for name in bus.list_names():
            if name.startswith('org.mpris.MediaPlayer2.'):
                try:
                    player_obj = bus.get_object(name, '/org/mpris/MediaPlayer2')
                    iface = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
                    status = str(iface.Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus'))
                    players.append((name, status))
                except Exception:
                    pass
    except Exception:
        pass
        
    if not players:
        return None
        
    # Prefer currently playing player
    for name, status in players:
        if status == 'Playing':
            return name
    return players[0][0]

def main():
    if len(sys.argv) < 2:
        return
    action = sys.argv[1]
    
    bus = dbus.SessionBus()
    player = get_active_player(bus)
    if not player:
        return
        
    try:
        player_obj = bus.get_object(player, '/org/mpris/MediaPlayer2')
        player_iface = dbus.Interface(player_obj, 'org.mpris.MediaPlayer2.Player')
        if action == 'play':
            player_iface.PlayPause()
        elif action == 'next':
            player_iface.Next()
        elif action == 'prev':
            player_iface.Previous()
    except Exception as e:
        print("Error sending command:", e)

if __name__ == '__main__':
    main()
