#!/bin/bash
# Network state for the bar and the Network popup: active connections, wired
# devices, Wi-Fi networks in range, VPNs and saved Wi-Fi profiles

get_network() {
  local devices connections networks details profiles vpninfo

  devices=$(nmcli -t -f DEVICE,TYPE,STATE device)
  connections=$(nmcli -t -f NAME,UUID,TYPE,DEVICE,AUTOCONNECT,STATE connection show)
  networks=$(nmcli -t -f IN-USE,BSSID,SSID,FREQ,SIGNAL,SECURITY device wifi list --rescan no 2> /dev/null)

  # IP details of active connections: uuid, address, gateway, dns, speed
  details=$(nmcli -t -f UUID,DEVICE connection show --active | while IFS=: read -r uuid device; do
    [[ -z "$device" || "$device" == "lo" ]] && continue
    mapfile -t info < <(nmcli -g IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,CAPABILITIES.SPEED device show "$device")
    printf '%s\t%s\t%s\t%s\t%s\n' "$uuid" "${info[0]}" "${info[1]}" "${info[2]}" "${info[3]}"
  done)

  # Saved Wi-Fi profiles can be named differently from their SSID: uuid, ssid
  profiles=$(nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do
    [[ "$type" == "802-11-wireless" ]] || continue
    printf '%s\t%s\n' "$uuid" "$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid")"
  done)

  # Saved VPN settings: uuid, type, server, address, dns, last used
  vpninfo=$(nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do
    [[ "$type" == "vpn" || "$type" == "wireguard" ]] || continue
    mapfile -t info < <(nmcli -g connection.timestamp,ipv4.addresses,ipv4.dns,vpn.service-type,vpn.data connection show uuid "$uuid")
    case "$type:${info[3]}" in
      wireguard:*) kind="WireGuard" ;;
      *openvpn) kind="OpenVPN" ;;
      *) kind="VPN" ;;
    esac
    # WireGuard endpoints are only readable by root, OpenVPN keeps it in vpn.data
    server=$(grep -oP '(^|, )remote = \K[^,]*' <<< "${info[4]}")
    used="Never"
    (( ${info[0]:-0} > 0 )) && used=$(date -d "@${info[0]}" '+%b %-d, %Y')
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$uuid" "$kind" "$server" "${info[1]//,/, }" "${info[2]//,/, }" "$used"
  done)

  jq -n -c \
    --arg devices "$devices" \
    --arg connections "$connections" \
    --arg networks "$networks" \
    --arg details "$details" \
    --arg profiles "$profiles" \
    --arg vpninfo "$vpninfo" \
    --arg radio "$(nmcli radio wifi)" '
    def lines: split("\n") | map(select(length > 0));
    def unescape: gsub("\\\\(?<c>.)"; .c);
    # nmcli -t separates fields with ":" and escapes ":" and "\" inside values
    def terse: [splits("(?<!\\\\):")] | map(unescape);

    def signal_icon:
      "network-wireless-signal-" + (
        if . >= 80 then "excellent"
        elif . >= 55 then "good"
        elif . >= 30 then "ok"
        elif . >= 5 then "weak"
        else "none" end) + "-symbolic";

    def band:
      if .freq >= 5925 then "6 GHz" elif .freq >= 5000 then "5 GHz" else "2.4 GHz" end;

    ($devices | lines | map(terse | {device: .[0], type: .[1], state: .[2]})) as $devices
    | ($connections | lines | map(terse | {
      name: .[0],
      uuid: .[1],
      type: .[2],
      device: .[3],
      autoconnect: (.[4] == "yes"),
      # Still activating connections stay in their list, marked as connecting
      active: (.[5] | IN("activated", "deactivating")),
      connecting: (.[5] == "activating")
    })) as $connections
    | ($connections | map(select(.connecting) | .uuid)) as $connecting
    | ($details | lines | map(split("\t") | {
      key: .[0],
      value: {
        ip: (.[1] | split(" | ")[0]),
        gateway: .[2],
        dns: (.[3] | split(" | ") | join(", ")),
        speed: .[4]
      }
    }) | from_entries) as $details
    | ($profiles | lines | map(split("\t") | {uuid: .[0], ssid: (.[1] | unescape)})) as $profiles
    | ($vpninfo | lines | map(split("\t") | {
      key: .[0],
      value: {type: .[1], server: .[2], address: .[3], vpn_dns: .[4], last_used: .[5]}
    }) | from_entries) as $vpninfo

    # Access points grouped by SSID, keeping the strongest one
    | ($networks | lines | map(terse | {
      active: (.[0] == "*"),
      bssid: .[1],
      ssid: .[2],
      freq: (.[3] | split(" ")[0] | tonumber? // 0),
      signal: (.[4] | tonumber? // 0),
      security: (if .[5] == "--" then "" else .[5] end)
    }) | map(select(.ssid != ""))) as $aps
    | ($aps | group_by(.ssid) | map(
      max_by(.signal) as $best
      | $best + {
        active: any(.[]; .active),
        bands: (map(band) | unique | join(", ")),
        secured: ($best.security != ""),
        enterprise: ($best.security | test("802\\.1X")),
        saved_uuid: (($profiles | map(select(.ssid == $best.ssid)) | first.uuid) // ""),
        connecting: any($profiles[]; .ssid == $best.ssid and (.uuid | IN($connecting[]))),
        icon: ($best.signal | signal_icon)
      })) as $wifi

    | ($connections
      | map(select(.active and (.type | IN("802-11-wireless", "802-3-ethernet", "vpn", "wireguard"))))
      | map(
        (.type | if . == "802-11-wireless" then "wifi" elif . == "802-3-ethernet" then "ethernet" else "vpn" end) as $kind
        | ($aps | map(select(.active)) | first) as $ap
        | {uuid, name, device, autoconnect, kind: $kind, server: ""}
        + ($details[.uuid] // {ip: "", gateway: "", dns: "", speed: ""})
        + if $kind == "wifi" then {icon: (($ap.signal // 0) | signal_icon), detail: (if $ap then $ap | band else "" end)}
          elif $kind == "ethernet" then {icon: "network-wired-symbolic", detail: .speed}
          else {icon: "network-vpn-symbolic", detail: ($vpninfo[.uuid].type // "VPN"), server: ($vpninfo[.uuid].server // "")} end)
      | sort_by(.kind | {ethernet: 0, wifi: 1, vpn: 2}[.])) as $active

    | ($wifi | map(select((.active | not) or .connecting)) | sort_by(-.signal)) as $available
    | ($available | map(.ssid)) as $in_range
    | ($devices | map(select(.type == "wifi")) | first.device // "") as $wifi_device

    | {
      wifi_device: $wifi_device,
      wifi_enabled: ($radio == "enabled"),
      icon: (
        if any($active[]; .kind == "ethernet") then "network-wired-symbolic"
        elif any($active[]; .kind == "wifi") then ($active | map(select(.kind == "wifi")) | first.icon)
        elif $wifi_device != "" and $radio != "enabled" then "network-wireless-disabled-symbolic"
        else "network-offline-symbolic" end),
      tooltip: (if $active == [] then "Disconnected" else $active | map(.name) | join(", ") end),
      # Active connections are listed at the top of their own section
      wired_active: ($active | map(select(.kind == "ethernet"))),
      wifi_active: ($active | map(select(.kind == "wifi"))),
      vpn_active: ($active | map(select(.kind == "vpn"))),
      wired: ($devices
        | map(select(.type == "ethernet" and (.state == "disconnected" or (.state | startswith("connecting")))))
        | map({device, name: "Wired (\(.device))", connecting: (.state != "disconnected")})),
      networks: $available,
      vpns: ($connections
        | map(select((.type == "vpn" or .type == "wireguard") and (.active | not)))
        | map({uuid, name, autoconnect, connecting} + ($vpninfo[.uuid] // {}))),
      saved: ($connections
        | map(select(.type == "802-11-wireless" and (.active | not)))
        | map(. as $c | select(($profiles | map(select(.uuid == $c.uuid)) | first.ssid // $c.name) as $ssid
          | $in_range | index($ssid) | not))
        | map({uuid, name, autoconnect})
        | sort_by(.name | ascii_downcase))
    }'
}

print_if_changed() {
  local current
  current=$(get_network)
  if [[ "$current" != "$last" ]]; then
    last=$current
    echo "$current"
  fi
}

# NetworkManager events and scan-network.sh both write to this FIFO to ask for a refresh
fifo="${XDG_RUNTIME_DIR:-/tmp}/eww-network.fifo"
[[ -p "$fifo" ]] || mkfifo "$fifo"
# Opened read-write so it never reaches EOF when a writer closes it
exec 3<> "$fifo"

(while true; do nmcli monitor; sleep 5; done) > "$fifo" &
monitor=$!
trap 'pkill -P "$monitor"; kill "$monitor"' EXIT
trap 'exit' TERM INT HUP

last=""
print_if_changed

while true; do
  # Refresh on events, a finished scan, or every 30s for signal strength
  read -r -t 30 -u 3 _
  while read -r -t 0.3 -u 3 _; do :; done
  print_if_changed
done
