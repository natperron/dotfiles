#!/bin/bash

# Nerd Font battery glyphs: outline, 10%, 20% ... 90%, full
BATTERY_ICONS=(
  $'\U000F008E' $'\U000F007A' $'\U000F007B' $'\U000F007C' $'\U000F007D' $'\U000F007E'
  $'\U000F007F' $'\U000F0080' $'\U000F0081' $'\U000F0082' $'\U000F0079'
)

get_bluetooth_devices() {
  bluetoothctl devices | while read -r kind mac name; do
    # bluetoothctl can print [NEW]/[CHG] lines, only keep devices
    [[ "$kind" == "Device" ]] || continue
    # Unnamed devices found while scanning use their address as name
    [[ -z "$name" || "$name" == "${mac//:/-}" ]] && continue

    paired=false connected=false icon="bluetooth" battery=""
    while IFS= read -r line; do
      case "$line" in
        *"Paired: yes") paired=true ;;
        *"Connected: yes") connected=true ;;
        *"Icon: "*) icon=${line##*Icon: } ;;
        *"Battery Percentage:"*) battery=${line##*(}; battery=${battery%)} ;;
      esac
    done < <(bluetoothctl info "$mac")

    battery_icon=""
    [[ -n "$battery" ]] && battery_icon=${BATTERY_ICONS[$(( (battery + 5) / 10 ))]}

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$mac" "$name" "$paired" "$connected" "$icon" "$battery" "$battery_icon"
  done | jq -R -s -c '
    split("\n")
    | map(select(length > 0) | split("\t") | {
      id: .[0],
      name: .[1],
      paired: (.[2] == "true"),
      connected: (.[3] == "true"),
      icon: .[4],
      battery: .[5],
      battery_icon: .[6]
    })
    | sort_by((.connected | not), (.paired | not), (.name | ascii_downcase))'
}

get_bluetooth_devices

dbus-monitor --system "type='signal',sender='org.bluez'" 2> /dev/null |
while read -r line; do
  [[ "$line" == signal* ]] || continue
  # Coalesce bursts of signals (e.g. RSSI updates while scanning)
  while read -r -t 0.5 _; do :; done
  get_bluetooth_devices
done
