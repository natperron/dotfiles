#!/bin/bash
# i3 doesn't respect stalonetray's geometry once it's in the scratchpad,
# so pin it to the top-right of the focused output on every show
place_tray() {
    local out ox oy ow w
    out=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')
    read -r ox oy ow < <(i3-msg -t get_outputs | jq -r --arg o "$out" \
        '.[] | select(.name == $o) | "\(.rect.x) \(.rect.y) \(.rect.width)"')
    # Width of the floating container, so the i3 border is included
    w=$(i3-msg -t get_tree | jq '[.. | objects | select(.type == "floating_con")
        | select(any(.nodes[]; .window_properties.class == "stalonetray"))][0].rect.width')
    i3-msg "[class=\"stalonetray\"] move absolute position $((ox + ow - w - 10)) $((oy + 45))"
}

show_tray() {
    ~/.config/eww/scripts/popup.sh --close-all
    eww update tray=true
    i3-msg [class="stalonetray"] scratchpad show
    place_tray
    pidof tray-icon-fix || (tray-icon-fix &)
    sleep 0.2
    pkill tray-icon-fix
}

hide_tray() {
    eww update tray=false;
    i3-msg [class="stalonetray"] move scratchpad
}

if [[ $(eww get tray) == false ]]; then
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
