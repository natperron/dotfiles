#!/bin/bash
show_tray() {
    eww update tray=true
    i3-msg [class="stalonetray"] scratchpad show
    pidof tray-icon-fix || (tray-icon-fix &)
    sleep 0.2
    pkill tray-icon-fix
}

hide_tray() {
    eww update tray=false;
    i3-msg [class="stalonetray"] move scratchpad
}

if [[ $1 == false ]]; then
    show_tray
    while i3-msg -t subscribe '["window"]' > /dev/null; do
        sleep 0.5
        xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
        [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && break
        wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
        [[ "$wm_class" != "stalonetray" ]] && break
    done
    hide_tray
else
    hide_tray
fi
