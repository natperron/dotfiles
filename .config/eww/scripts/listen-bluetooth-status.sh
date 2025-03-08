#!/bin/bash

get_bluetooth_status() {
    icon="bluetooth-offline"  # Bluetooth powered off icon
    powered=$(bluetoothctl show | grep "Powered: yes" &> /dev/null && echo true || echo false)
    scanning=$(bluetoothctl show | grep "Discovering: yes" &> /dev/null && echo true || echo false)
    
    if $powered; then
        if bluetoothctl info | grep -q "Connected: yes"; then
            icon="bluetooth-paired"  # Bluetooth connected icon
        else
            icon="bluetooth-online"  # Bluetooth disconnected icon
        fi
    fi

    echo "{\"icon\":\"$icon\",\"powered\": $powered,\"scanning\": $scanning}"
}

get_bluetooth_status

dbus-monitor --system "sender='org.bluez',member=PropertiesChanged" 2> /dev/null | 
while read -r line; do
    if echo $line | grep "signal" > /dev/null; then
        get_bluetooth_status
    fi
done