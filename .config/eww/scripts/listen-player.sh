#!/bin/bash

get_player() {
    if playerctl -p spotify,Feishin metadata &> /dev/null ; then
        title=$(playerctl -p spotify,Feishin metadata -f "{{artist}} - {{title}}" | sed -E 's/(.{40}).+/\1.../')
        playing=$(playerctl -p spotify,Feishin status 2> /dev/null | grep Playing > /dev/null && echo true || echo false)
        out="{\"player\":true,\"title\":\"$title\",\"playing\":$playing}"
    else
        out="{\"player\":false,\"title\":\"No music playing\"}";
    fi

    echo $out
}

get_player;
dbus-monitor \
    --profile "sender=org.mpris.MediaPlayer2.Feishin,member=PropertiesChanged" \
    --profile "member=RemoveMatch" \
    --profile "sender=org.mpris.MediaPlayer2.spotify,member=PropertiesChanged" |
    #--profile "sender=org.mpris.MediaPlayer2.spotify,member=RemoveMatch" |
while read -r line; do
    get_player;
done;
