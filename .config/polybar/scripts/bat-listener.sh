#!/bin/bash
dbus-monitor --system --profile "path=/org/freedesktop/UPower/devices/battery_BAT0,member=PropertiesChanged" |
while read -r line; do
  polybar-msg action "#bat.hook.0"
done
