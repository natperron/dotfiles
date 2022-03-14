#!/bin/sh

killall -q polybar

for monitor in $(xrandr | grep " connected" | sed -e 's/ /,/g') ; do
    if [ ! -z $( echo $monitor | grep "primary") ] ; then	
        MONITOR=$( echo $monitor | cut -d "," -f1) polybar primary &
    else
        MONITOR=$( echo $monitor | cut -d "," -f1) polybar main &
    fi
done

#MONITOR=eDP polybar primary &
