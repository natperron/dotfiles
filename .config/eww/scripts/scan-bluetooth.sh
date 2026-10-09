#!/bin/bash
# Discovery stops when bluetoothctl exits, so keep it alive for the duration.
# The button sets bluetoothscanning itself so it is disabled right away.

trap 'eww update bluetoothscanning=false' EXIT
bluetoothctl --timeout 15 scan on &> /dev/null
