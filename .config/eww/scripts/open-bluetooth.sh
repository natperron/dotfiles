#!/bin/bash
show_bluetooth() {
    eww update bluetoothselected=""
    eww update bluetoothopen=true
    eww open bluetooth --screen $1 --arg monitor=$1
}

hide_bluetooth() {
    eww update bluetoothopen=false
    eww close bluetooth
    eww update bluetoothpicker=false
    eww close bluetooth-audio-profile
}

if [[ $(eww get bluetoothopen) == false ]]; then
    show_bluetooth $1
    while i3-msg -t subscribe '["window"]' > /dev/null; do
        sleep 0.5
        xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
        [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && break
        wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
        wm_name=$(xprop -id "$xpropid" WM_NAME | awk '{print $NF}' | tr -d '"')
        [[ "$wm_class" != "eww" && "$wm_name" != "bluetooth" && "$wm_name" != "picker" ]] && break
    done
    hide_bluetooth
else
    hide_bluetooth
fi