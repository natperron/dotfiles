#!/bin/bash
pidof eww && eww kill;
pidof eww && killall -9 eww;

pidof stalonetray || (stalonetray &) && i3-msg [class="stalonetray"] move scratchpad;
count=0;
eww daemon;
for monitor in $(xrandr --listactivemonitors | awk '/^[[:space:]]*[0-9]:/ {print $NF}'); do
  eww open bar --id $monitor --screen $monitor --arg monitor=$monitor;
  count=$((count + 1));
done
