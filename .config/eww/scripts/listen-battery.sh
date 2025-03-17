#!/bin/bash

get_battery() {
    status=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | awk '/state:/ {print $2}')
    percent=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | awk '/percentage:/ {print substr($2, 1, length($2)-1)}')
    icon=""

    if [ $warning_sent ] && [ $status != 'discharging' ]; then
        warning_sent=false
    fi
    if [ ! $warning_sent ] && [ $status == 'discharging' ] && [ $percent -lt 10 ]; then
        notify-send "Low Battery!";
        warning_sent=true
    fi

    if [ $percent -ge 98 ]; then
        icon="battery-100"
    elif [ $percent -ge 90 ]; then
        icon="battery-090"
    elif [ $percent -ge 80 ]; then
        icon="battery-080"
    elif [ $percent -ge 70 ]; then
        icon="battery-070"
    elif [ $percent -ge 60 ]; then
        icon="battery-060"
    elif [ $percent -ge 50 ]; then
        icon="battery-050"
    elif [ $percent -ge 40 ]; then
        icon="battery-040"
    elif [ $percent -ge 30 ]; then
        icon="battery-030"
    elif [ $percent -ge 20 ]; then
        icon="battery-020"
    elif [ $percent -ge 10 ]; then
        icon="battery-010"
    else
        icon="battery-000"
    fi
    
    if [ $status != 'discharging' ]; then
        icon="${icon}-charging"
    fi

    echo "{\"icon\":\"$icon\",\"percent\":\"$percent\"}"
}

get_battery
dbus-monitor --system --profile "path=/org/freedesktop/UPower/devices/battery_BAT0,member=PropertiesChanged" |
while read -r line; do
    get_battery
done
