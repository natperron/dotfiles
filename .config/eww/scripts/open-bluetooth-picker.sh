#!/bin/bash
show_bluetooth_picker() {
    eww update bluetoothpicker=true
    eww open picker --screen $3 \
        --anchor "top right" \
        --id "bluetooth-audio-profile" \
        --arg items="$1" \
        --arg onchange="~/.config/eww/scripts/set-bluetooth-profile.sh $2" \
        --arg y="$4" \
        --arg x="-58"
}

hide_bluetooth_picker() {
    eww update bluetoothpicker=false
    eww close bluetooth-audio-profile
}

if [[ $(eww get bluetoothpicker) == false ]]; then
    show_bluetooth_picker "$1" "$2" "$3" "$4"
    while i3-msg -t subscribe '["window"]' > /dev/null; do
        sleep 0.5
        xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
        [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && break
        wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
        wm_name=$(xprop -id "$xpropid" WM_NAME | awk '{print $NF}' | tr -d '"')
        [[ "$wm_class" != "eww" && "$wm_name" != "bluetooth" && "$wm_name" != "picker" ]] && break
    done
    hide_bluetooth_picker
else
    hide_bluetooth_picker
fi