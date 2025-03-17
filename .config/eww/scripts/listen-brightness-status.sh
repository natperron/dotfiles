#!/bin/bash
get_brightness() {
    has_backlight=$(brightnessctl --class=backlight &> /dev/null && echo "true" || echo "false")
    current=$(brightnessctl --class=backlight get 2> /dev/null || echo "0")
    max=$(brightnessctl --class=backlight max 2> /dev/null || echo "0")
    percentage=$([ $max -gt 0 ] && echo $((current * 100 / max)) || echo "0")
    if [ "$percentage" -gt 70 ]; then
        icon="brightness-high-symbolic"
    elif [ "$percentage" -lt 30 ]; then
        icon="brightness-low-symbolic"
    else
        icon="brightness-medium-symbolic"
    fi
    echo "{\"has_backlight\":$has_backlight,\"current\":$current,\"max\":$max,\"icon\":\"$icon\"}"
}

get_brightness
dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/UPower/devices/backlight'" 2> /dev/null | 
while read -r; do
    get_brightness
done
