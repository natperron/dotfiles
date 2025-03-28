#!/bin/bash
show_bluetooth() {
    eww close brightness
    eww update bluetoothselected=""
    eww open systemwidget \
        --screen $1 \
        --toggle \
        --arg monitor=$1 \
        --arg title="Bluetooth" \
        --arg titlecontent="(bluetooth-titlecontent)" \
        --arg body="(bluetooth-content :monitor monitor)" \
        --id "bluetooth"
}

hide_bluetooth() {
    eww close bluetooth bluetooth-audio-profile
}

if [ -z $(eww active-windows | grep bluetooth) ]; then
    show_bluetooth $1
    while i3-msg -t subscribe '["window"]' > /dev/null; do
        sleep 0.5
        xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
        [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && break
        wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
        wm_name=$(xprop -id "$xpropid" WM_NAME | awk '{print $NF}' | tr -d '"')
        [[ "$wm_class" != "eww" && "$wm_name" != "systemwidget" && "$wm_name" != "picker" ]] && break
    done
    hide_bluetooth
else
    hide_bluetooth
fi