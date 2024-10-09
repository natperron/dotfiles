#!/bin/bash
eww kill;
barsfile="$HOME/.config/eww/yuck/bars.yuck";

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
    toeval="$toeval eww open bar$count &"
    count=$((count + 1));
done

eww daemon &
eval $toeval
