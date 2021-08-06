#!/bin/sh

killall -q polybar

MONITOR=DP-2 polybar main & 
MONITOR=HDMI-1 polybar main & 
MONITOR=eDP-1 polybar primary &

