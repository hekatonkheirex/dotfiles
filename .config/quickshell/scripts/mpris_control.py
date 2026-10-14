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
        elif action == 'stop':
            player_iface.Stop()
        elif action == 'next':
            player_iface.Next()
        elif action == 'prev':
            player_iface.Previous()
        elif action == 'position':
            props = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
            print(int(props.Get('org.mpris.MediaPlayer2.Player', 'Position')) / 1000000.0)
        elif action == 'seek' and len(sys.argv) > 2:
            player_iface.Seek(dbus.Int64(int(float(sys.argv[2]) * 1000000)))
        elif action == 'seekto' and len(sys.argv) > 2:
            meta = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties').Get(
                'org.mpris.MediaPlayer2.Player', 'Metadata')
            track = meta.get('mpris:trackid')
            if track is not None:
                player_iface.SetPosition(track, dbus.Int64(int(float(sys.argv[2]) * 1000000)))
        elif action == 'volume' and len(sys.argv) > 2:
            props = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
            cur = float(props.Get('org.mpris.MediaPlayer2.Player', 'Volume'))
            props.Set('org.mpris.MediaPlayer2.Player', 'Volume',
                      dbus.Double(max(0.0, min(1.0, cur + float(sys.argv[2])))))
    except Exception as e:
        print("Error sending command:", e)

if __name__ == '__main__':
    main()
