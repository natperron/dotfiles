#!/bin/bash
# Connect or disconnect a network, showing errors in the popup.
# Typed text (password, hidden SSID) is read from stdin so it never ends up in
# an eww command, and network names are never passed through the shell.
# The buttons set networkbusy themselves so they are disabled right away.
#
# Usage: network-action.sh wifi <bssid>       new network, password on stdin (empty if open)
#        network-action.sh hidden             hidden network, password on stdin, SSID from networkhiddenssid
#        network-action.sh up <uuid> [key]    saved Wi-Fi, wired or VPN profile
#        network-action.sh down <uuid>        disconnect
#        network-action.sh device <device>    wired device without a profile
#        network-action.sh import             VPN config file, picked with zenity

action=$1
target=$2
key=${3:-${2:-$1}}

# Give the listener time to report the new state before re-enabling the button
trap 'sleep 1; eww update networkbusy=' EXIT
eww update networkerror=

before=$(nmcli -g UUID connection show)

case "$action" in
  wifi)
    IFS= read -r password
    if [[ -n "$password" ]]; then
      output=$(nmcli --wait 30 device wifi connect "$target" password "$password" 2>&1)
    else
      output=$(nmcli --wait 30 device wifi connect "$target" 2>&1)
    fi
    ;;
  hidden)
    IFS= read -r password
    ssid=$(eww get networkhiddenssid)
    if [[ -n "$password" ]]; then
      output=$(nmcli --wait 30 device wifi connect "$ssid" password "$password" hidden yes 2>&1)
    else
      output=$(nmcli --wait 30 device wifi connect "$ssid" hidden yes 2>&1)
    fi
    ;;
  up) output=$(nmcli --wait 30 connection up uuid "$target" 2>&1) ;;
  down) output=$(nmcli connection down uuid "$target" 2>&1) ;;
  device) output=$(nmcli --wait 30 device connect "$target" 2>&1) ;;
  import)
    file=$(zenity --file-selection --title "Import VPN" \
      --file-filter "VPN configs (.conf, .ovpn) | *.conf *.ovpn" 2> /dev/null) || exit 0
    case "${file,,}" in
      *.conf) output=$(nmcli connection import type wireguard file "$file" 2>&1) ;;
      *.ovpn) output=$(nmcli connection import type openvpn file "$file" 2>&1) ;;
      *) output="Error: Choose a WireGuard .conf or OpenVPN .ovpn file"; false ;;
    esac
    ;;
  *) exit 1 ;;
esac
status=$?
unset password

if (( status != 0 )); then
  # nmcli keeps the profile it created even when the first connection fails
  for uuid in $(nmcli -g UUID connection show); do
    grep -qx "$uuid" <<< "$before" || nmcli connection delete uuid "$uuid" &> /dev/null
  done

  message=$(grep -m 1 "Error" <<< "$output")
  message=${message##*Error: }
  if [[ "$key" == import && "$output" == *"plugin"* ]]; then
    message="OpenVPN support missing, install network-manager-openvpn"
  elif [[ "$output" == *"Secrets were required"* ]]; then
    message="Wrong password"
    [[ "$action" == "up" ]] && message="Wrong password, forget the network to enter it again"
  fi
  eww update networkerror="$key" networkerrormsg="${message:-Connection failed}"
else
  # Imported VPNs shouldn't take over all traffic until connected on purpose
  if [[ "$key" == import ]]; then
    for uuid in $(nmcli -g UUID connection show); do
      grep -qx "$uuid" <<< "$before" || nmcli connection modify uuid "$uuid" connection.autoconnect no
    done
  fi
  eww update networkselected= networkhiddenssid=
fi
