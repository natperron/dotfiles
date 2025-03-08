#!/bin/bash

get_bluetooth_devices() {
  devices=$(bluetoothctl devices)

  json_output="["

  while IFS= read -r line; do
    device_id=$(echo "$line" | awk '{print $2}')
    device_name=$(echo "$line" | cut -d ' ' -f 3-)
    paired=$(bluetoothctl info "$device_id" | grep -q "Paired: yes" && echo "true" || echo "false")
    connected=$(bluetoothctl info "$device_id" | grep -q "Connected: yes" && echo "true" || echo "false")

    json_output+="{\"id\":\"$device_id\",\"name\":\"$device_name\",\"paired\":$paired,\"connected\":$connected},"
  done <<< "$devices"

  # Remove the trailing comma and close the JSON array
  json_output="${json_output%,}]"

  # Print the JSON output
  echo "$json_output"
}

get_bluetooth_devices

dbus-monitor --system "sender='org.bluez',member=PropertiesChanged" 2> /dev/null | 
while read -r line; do
  if echo $line | grep "signal" > /dev/null; then
      get_bluetooth_devices
  fi
done