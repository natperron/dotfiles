#!/bin/bash

get_audio_profiles() {
  card_name="bluez_card.${1//:/_}"
  pw-dump | \
    jq -c --arg card_name "$card_name" '.[]
    | select(.info.props."device.name" == $card_name)
    | {
      card_id: .id, 
      selected_profile: .info.params.Profile[0] | {id: .index, name: .description},
      profiles: .info.params.EnumProfile | map({
        id: .index,
        name: .description
      })
    }'
}

get_bluetooth_devices() {
  devices=$(bluetoothctl devices)

  json_output="["

  while IFS= read -r line; do
    device_id=$(echo "$line" | awk '{print $2}')
    device_name=$(echo "$line" | cut -d ' ' -f 3-)
    paired=$(bluetoothctl info "$device_id" | grep -q "Paired: yes" && echo "true" || echo "false")
    connected=$(bluetoothctl info "$device_id" | grep -q "Connected: yes" && echo "true" || echo "false")
    audio_profiles=$(get_audio_profiles $device_id)


    device="{\"id\":\"$device_id\",\"name\":\"$device_name\",\"paired\":$paired,\"connected\":$connected,\"card_id\":null}"
    # device=$(jq --argjson device "$device" --argjson audio_profiles "$audio_profiles" '$device * $audio_profiles')

    json_output+="$(echo "$device" "$audio_profiles" | jq -c -s 'add'),"
  done <<< "$devices"

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
