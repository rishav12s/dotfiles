#!/usr/bin/env bash

if ! command -v nmcli &>/dev/null; then
  echo "{\"text\": \"󰤮\", \"tooltip\": \"nmcli utility is missing\"}"
  exit 1
fi

# Check if Wi-Fi is enabled
wifi_status=$(nmcli radio wifi)

if [ "$wifi_status" = "disabled" ]; then
  echo "{\"text\": \"󰤮\", \"tooltip\": \"Wi-Fi Disabled\"}"
  exit 0
fi

wifi_info=$(nmcli -t -f active,ssid,signal,security dev wifi | grep "^yes")

if [ -z "$wifi_info" ]; then
  essid="No Connection"
  signal=0
  tooltip="No Connection"
else
  security=$(echo "$wifi_info" | awk -F: '{print $4}')
  signal=$(echo "$wifi_info" | awk -F: '{print $3}')

  # Identify active Wi-Fi device
  active_device=$(nmcli -t -f DEVICE,TYPE,STATE device status |
    grep -w "wifi:connected" |
    awk -F: '{print $1}')

  if [ -n "$active_device" ]; then
    output=$(nmcli -e no -g ip4.address,general.hwaddr device show "$active_device")
    ip_address=$(echo "$output" | sed -n '1p')

    line=$(nmcli -e no -t -f active,bssid,chan,freq device wifi | grep "^yes")
    chan=$(echo "$line" | awk -F':' '{print $8}')
    freq=$(echo "$line" | awk -F':' '{print $9}')
    chan="$chan ($freq)"

    essid=$(echo "$wifi_info" | awk -F: '{print $2}')

    tooltip="${essid}\n"
    tooltip+="\nIP Address: ${ip_address}"
    tooltip+="\nSecurity:   ${security}"
    tooltip+="\nChannel:    ${chan}"
    tooltip+="\nStrength:   ${signal} / 100"
  fi
fi

# Determine Wi-Fi icon based on signal strength
if [ "$signal" -ge 80 ]; then
  icon="󰤨" # Strong signal
elif [ "$signal" -ge 60 ]; then
  icon="󰤥" # Good signal
elif [ "$signal" -ge 40 ]; then
  icon="󰤢" # Weak signal
elif [ "$signal" -ge 20 ]; then
  icon="󰤟" # Very weak signal
else
  icon="󰤮" # No signal
fi

# Module and tooltip
echo "{\"text\": \"${icon}\", \"tooltip\": \"${tooltip}\"}"