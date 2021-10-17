#!/bin/bash
dbus-monitor --profile "sender=org.mpris.MediaPlayer2.spotify,member=RemoveMatch" | 
while read -r line; do
    polybar-msg hook spotify-song 1
    polybar-msg hook spotify-controls 1
done &
dbus-monitor --profile "sender=org.mpris.MediaPlayer2.spotify,member=PropertiesChanged" |
while read -r line; do
    polybar-msg hook spotify-song 2
    polybar-msg hook spotify-controls 2
done
