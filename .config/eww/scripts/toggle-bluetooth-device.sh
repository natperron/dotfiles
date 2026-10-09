#!/bin/bash
# Connect or disconnect a device, pairing and trusting it first if needed
# Usage: toggle-bluetooth-device.sh <mac>
# The button sets bluetoothbusy itself so it is disabled right away

# Give the listener time to report the new state before re-enabling the button
trap 'sleep 1; eww update bluetoothbusy=' EXIT

info=$(bluetoothctl info "$1")

if grep -q "Connected: yes" <<< "$info"; then
    bluetoothctl disconnect "$1"
    exit
fi

if ! grep -q "Paired: yes" <<< "$info"; then
    timeout 20 bluetoothctl pair "$1" || exit 1
    bluetoothctl trust "$1"
fi
timeout 20 bluetoothctl connect "$1"
