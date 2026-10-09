#!/bin/bash
# Toggle a systemwidget popup, closing any other popup, and close it again
# once focus moves to a non-eww window.
# Usage: popup.sh <id> <monitor> <title> <body> [titlecontent]

POPUPS=(bluetooth audio wifi brightness battery)

id=$1
monitor=$2
title=$3
body=$4
titlecontent=${5:-}
pidfile="${XDG_RUNTIME_DIR:-/tmp}/eww-popup.pid"

is_open() {
    eww active-windows | grep -q "^$1:"
}

# Only one focus watcher at a time, otherwise a stale one closes the new popup
[[ -f "$pidfile" ]] && kill "$(cat "$pidfile")" 2> /dev/null
rm -f "$pidfile"

if is_open "$id"; then
    eww close "$id"
    exit 0
fi

for popup in "${POPUPS[@]}"; do
    is_open "$popup" && eww close "$popup"
done

eww open systemwidget \
    --id "$id" \
    --screen "$monitor" \
    --arg monitor="$monitor" \
    --arg title="$title" \
    --arg titlecontent="$titlecontent" \
    --arg body="$body"

echo $$ > "$pidfile"
while i3-msg -t subscribe '["window"]' > /dev/null; do
    sleep 0.5
    xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
    [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && break
    wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
    wm_name=$(xprop -id "$xpropid" WM_NAME | awk '{print $NF}' | tr -d '"')
    [[ "${wm_class,,}" != "eww" && "$wm_name" != "systemwidget" ]] && break
done
eww close "$id"
rm -f "$pidfile"
