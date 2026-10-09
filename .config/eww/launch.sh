#!/bin/bash
pidof eww && eww kill;
pidof eww && killall -9 eww;

# i3 for_window rule moves new stalonetray windows to the scratchpad
pidof stalonetray || (stalonetray &);
count=0;
eww daemon;
for monitor in $(xrandr --listactivemonitors | awk '/^[[:space:]]*[0-9]:/ {print $NF}'); do
  eww open bar --id $monitor --screen $monitor --arg monitor=$monitor;
  count=$((count + 1));
done
