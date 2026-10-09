#!/bin/bash
# The button sets networkscanning itself so it is disabled right away

trap 'eww update networkscanning=false' EXIT

# Waits until the scan is done, then asks listen-network.sh to refresh
nmcli device wifi list --rescan yes &> /dev/null
timeout 1 sh -c 'echo scan > "$1"' _ "${XDG_RUNTIME_DIR:-/tmp}/eww-network.fifo"
