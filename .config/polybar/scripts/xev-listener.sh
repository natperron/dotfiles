#!/bin/bash
xev -root -event property |
while read -r line; do
    echo $line | grep _NET_ACTIVE_WINDOW > /dev/null && polybar-msg action "#xwindowdesktop.hook.1"
done
