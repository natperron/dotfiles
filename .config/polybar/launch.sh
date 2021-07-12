#!/usr/bin/env sh

killall -q polybar

# while pgrep -x polybar >/dev/null; do sleep 1; done

# if type "xrandr"; then
#   for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
#     MONITOR=$m polybar --reload example &
#   done
# else
#   polybar --reload main &

# fi

MONITOR=HDMI-1 polybar main & 
MONITOR=DP-2 polybar main & 
MONITOR=eDP-1 polybar primary &