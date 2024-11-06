#!/bin/bash
pidof eww && eww kill;
pidof eww && killall -9 eww;
barsfile="/home/tlm/.config/eww/yuck/bars.yuck";

pidof stalonetray || (stalonetray &) && i3-msg [class="stalonetray"] move scratchpad;
echo "" > "$barsfile";
count=0;
toeval="";
for monitor in $(xrandr --listactivemonitors | awk '/^[[:space:]]*[0-9]:/ {print $NF}'); do
    cat >> "$barsfile" << EOL
(defwindow bar$count
  :monitor "$monitor"
  :windowtype "dock"
  :geometry 
    (geometry
      :y "0"
      :width "100%"
      :height "45px"
      :anchor "top center")
  (bar :monitor "$monitor"))

EOL
    toeval="$toeval eww open bar$count &&"
    count=$((count + 1));
done
toeval="$toeval exit 0"

eww daemon &&
eval $toeval 
