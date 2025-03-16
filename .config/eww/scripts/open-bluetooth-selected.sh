#!/bin/bash

selected=$(eww get bluetoothselected)
if [[ "$selected" == "$1" ]]; then
  eww update bluetoothselected=""
else
  eww update bluetoothselected="$1"
fi
