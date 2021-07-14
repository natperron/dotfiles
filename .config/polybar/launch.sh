#!/bin/sh

killall -q polybar

MONITOR=DP-5 polybar main & 
MONITOR=DP-2 polybar primary &

