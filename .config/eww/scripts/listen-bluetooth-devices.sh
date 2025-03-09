#!/bin/bash

get_audio_profiles() {
  card_name="bluez_card.${1//:/_}"
  card_id=$(pw-cli list-objects | grep $card_name -B 6 | grep -e "id " | head -1 | awk {'print $2'} | cut -d ',' -f 1) 
  
  [ -z $card_id ] && echo ",\"card_id\":null,\"profiles\":[]" && return

  json_output=",\"card_id\":$card_id,\"profiles\":["

  profiles=$(pw-cli e "$card_name" EnumProfile | grep -A 1 -e "Profile.index" -e "Profile.description" | grep -e "Int" -e "String \"")

  while IFS= read -r id && IFS= read -r name; do
    parsed_id=$(echo "$id" | awk {'print $2'})
    parsed_name=$(echo "$name" | cut -d '"' -f 2)
    json_output+="{\"id\":$parsed_id,\"name\":\"$parsed_name\"},"
  done <<< "$profiles"

  json_output="${json_output%,}]"
  echo "$json_output"
}

get_bluetooth_devices() {
  devices=$(bluetoothctl devices)

  json_output="["

  while IFS= read -r line; do
    device_id=$(echo "$line" | awk '{print $2}')
    device_name=$(echo "$line" | cut -d ' ' -f 3-)
    paired=$(bluetoothctl info "$device_id" | grep -q "Paired: yes" && echo "true" || echo "false")
    connected=$(bluetoothctl info "$device_id" | grep -q "Connected: yes" && echo "true" || echo "false")

    json_output+="{\"id\":\"$device_id\",\"name\":\"$device_name\",\"paired\":$paired,\"connected\":$connected"
    json_output+=$(get_audio_profiles "$device_id")
    json_output+="},"
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