#!/bin/bash

eww update bluetoothscan=true
bluetoothctl --timeout 10 scan on &> /dev/null && eww update bluetoothscan=false
