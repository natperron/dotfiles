#!/bin/bash
killall -9 eww;

pidof stalonetray || (stalonetray &) && i3-msg [class="stalonetray"] move scratchpad &
eww daemon &
eww open bar0 &
eww open bar1 &