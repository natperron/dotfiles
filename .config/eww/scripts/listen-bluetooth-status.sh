#!/bin/bash

get_bluetooth_status() {
    show=$(bluetoothctl show)
    powered=false scanning=false icon="bluetooth-offline"
    grep -q "Powered: yes" <<< "$show" && powered=true
    grep -q "Discovering: yes" <<< "$show" && scanning=true

    if $powered; then
        if bluetoothctl devices Connected | grep -q "^Device"; then
            icon="bluetooth-paired"
        else
            icon="bluetooth-online"
        fi
    fi

    echo "{\"icon\":\"$icon\",\"powered\":$powered,\"scanning\":$scanning}"
}

get_bluetooth_status

dbus-monitor --system "type='signal',sender='org.bluez'" 2> /dev/null |
while read -r line; do
    [[ "$line" == signal* ]] || continue
    while read -r -t 0.5 _; do :; done
    get_bluetooth_status
done
