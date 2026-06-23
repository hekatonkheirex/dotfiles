#!/usr/bin/env python3
import sys
import json
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

# We'll run the DBus main loop
DBusGMainLoop(set_as_default=True)

bus = dbus.SessionBus()

# Dictionary to hold the properties of each player
players = {}

def get_player_info(sender):
    try:
        player_obj = bus.get_object(sender, '/org/mpris/MediaPlayer2')
        iface = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
        playback_status = str(iface.Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus'))
        metadata = iface.Get('org.mpris.MediaPlayer2.Player', 'Metadata')
        
        title = ""
        artist = ""
        album = ""
        art_url = ""
        length_sec = 0
        length_str = "0:00"
        
        if 'xesam:title' in metadata:
            title = str(metadata['xesam:title'])
        if 'xesam:artist' in metadata:
            artist = ", ".join([str(x) for x in metadata['xesam:artist']])
        if 'xesam:album' in metadata:
            album = str(metadata['xesam:album'])
        if 'mpris:artUrl' in metadata:
            art_url = str(metadata['mpris:artUrl'])
        if 'mpris:length' in metadata:
            # Length is in microseconds
            length_sec = int(metadata['mpris:length']) // 1000000
            length_str = f"{length_sec // 60}:{length_sec % 60:02d}"
            
        return {
            'sender': sender,
            'status': playback_status,
            'title': title,
            'artist': artist,
            'album': album,
            'artUrl': art_url,
            'length_sec': length_sec,
            'length_str': length_str
        }
    except Exception as e:
        return None

preferred_player_sender = None

def update_and_print():
    global preferred_player_sender
    # Verify preferred player is still active
    if preferred_player_sender and preferred_player_sender not in players:
        preferred_player_sender = None

    active = None
    if preferred_player_sender:
        active = players.get(preferred_player_sender)

    if not active:
        # Find the best active player
        for sender, info in players.items():
            if info:
                if active is None:
                    active = info
                    preferred_player_sender = sender
                elif info['status'] == 'Playing' and active['status'] != 'Playing':
                    active = info
                    preferred_player_sender = sender
    
    if active:
        sys.stdout.write(json.dumps(active) + "\n")
    else:
        sys.stdout.write(json.dumps({
            'status': 'NoPlayer', 'title': '', 'artist': '', 'album': '', 
            'artUrl': '', 'length_sec': 0, 'length_str': '0:00'
        }) + "\n")
    sys.stdout.flush()

def handle_properties_changed(interface, changed_properties, invalidated_properties, path=None, sender=None):
    if interface == 'org.mpris.MediaPlayer2.Player':
        info = get_player_info(sender)
        if info:
            players[sender] = info
            update_and_print()

def name_owner_changed(name, old_owner, new_owner):
    global preferred_player_sender
    if name.startswith('org.mpris.MediaPlayer2.'):
        if new_owner == '':
            # Player exited
            if old_owner in players:
                del players[old_owner]
            if preferred_player_sender == old_owner:
                preferred_player_sender = None
            update_and_print()
        else:
            # Player joined
            info = get_player_info(new_owner)
            if info:
                players[new_owner] = info
                update_and_print()

# Initial scan
try:
    dbus_obj = bus.get_object('org.freedesktop.DBus', '/org/freedesktop/DBus')
    dbus_iface = dbus.Interface(dbus_obj, 'org.freedesktop.DBus')
    names = dbus_iface.ListNames()
    for name in names:
        if name.startswith('org.mpris.MediaPlayer2.'):
            owner = dbus_iface.GetNameOwner(name)
            info = get_player_info(owner)
            if info:
                players[owner] = info
except Exception as e:
    sys.stderr.write(f"Initial scan error: {e}\n")
    sys.stderr.flush()

# Subscribe to name changes
bus.add_signal_receiver(name_owner_changed, signal_name='NameOwnerChanged', dbus_interface='org.freedesktop.DBus')

# Subscribe to properties changed on any player
bus.add_signal_receiver(
    handle_properties_changed,
    signal_name='PropertiesChanged',
    dbus_interface='org.freedesktop.DBus.Properties',
    path='/org/mpris/MediaPlayer2',
    sender_keyword='sender'
)

# Helper function to send commands
def send_command(action):
    global preferred_player_sender
    active_sender = preferred_player_sender
    if not active_sender or active_sender not in players:
        # Fallback
        active = None
        for sender, info in players.items():
            if info:
                if active is None:
                    active = info
                    active_sender = sender
                elif info['status'] == 'Playing' and active['status'] != 'Playing':
                    active = info
                    active_sender = sender
                
    if not active_sender:
        return
        
    try:
        player_obj = bus.get_object(active_sender, '/org/mpris/MediaPlayer2')
        player_iface = dbus.Interface(player_obj, 'org.mpris.MediaPlayer2.Player')
        if action == 'play':
            player_iface.PlayPause()
        elif action == 'next':
            player_iface.Next()
        elif action == 'prev':
            player_iface.Previous()
    except Exception as e:
        sys.stderr.write(f"Error sending command: {e}\n")
        sys.stderr.flush()

def handle_cmd(cmd):
    global preferred_player_sender
    if cmd in ['play', 'next', 'prev']:
        send_command(cmd)
    elif cmd == 'shift':
        senders = list(players.keys())
        if senders:
            try:
                idx = senders.index(preferred_player_sender)
                preferred_player_sender = senders[(idx + 1) % len(senders)]
            except ValueError:
                preferred_player_sender = senders[0]
            update_and_print()

def read_fifo():
    import os
    FIFO = '/tmp/qsmpris-fifo'
    try:
        if os.path.exists(FIFO):
            os.remove(FIFO)
        os.mkfifo(FIFO)
    except OSError:
        pass
        
    while True:
        try:
            with open(FIFO, 'r') as fifo:
                for line in fifo:
                    cmd = line.strip()
                    if cmd:
                        handle_cmd(cmd)
        except Exception:
            pass

import threading
t = threading.Thread(target=read_fifo, daemon=True)
t.start()

update_and_print()

loop = GLib.MainLoop()
try:
    loop.run()
except KeyboardInterrupt:
    pass
