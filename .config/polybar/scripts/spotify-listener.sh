#!/bin/bash
dbus-monitor --profile "sender=org.mpris.MediaPlayer2.spotify,member=RemoveMatch" | 
while read -r line; do
    polybar-msg action "#spotify-song.hook.0"
    polybar-msg action "#spotify-controls.hook.0"
done &
dbus-monitor --profile "sender=org.mpris.MediaPlayer2.spotify,member=PropertiesChanged" |
while read -r line; do
    polybar-msg action "#spotify-song.hook.1"
    polybar-msg action "#spotify-controls.hook.1"
done
