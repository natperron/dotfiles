#!/bin/bash
show_brightness() {
    eww close bluetooth bluetooth-audio-profile
    eww open systemwidget \
        --id "brightness"  \
        --screen $1 \
        --toggle \
        --arg monitor=$1 \
        --arg title="Brightness" \
        --arg titlecontent="" \
        --arg body="(brightness-content)"
}

hide_brightness() {
    eww close brightness
}

if [ -z $(eww active-windows | grep brightness) ]; then
    show_brightness $1
    while i3-msg -t subscribe '["window"]' > /dev/null; do
        sleep 0.5
        xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
        [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && break
        wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
        wm_name=$(xprop -id "$xpropid" WM_NAME | awk '{print $NF}' | tr -d '"')
        [[ "$wm_class" != "eww" && "$wm_name" != "systemwidget" && "$wm_name" != "picker" ]] && break
    done
    hide_brightness
else
    hide_brightness
fi