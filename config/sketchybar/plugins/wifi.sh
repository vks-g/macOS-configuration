#!/bin/bash
# Wi-Fi icon + network name. ipconfig reads the SSID locally without Location
# Services on this macOS version; if a future update redacts it, only the icon shows.
# The name lives in the separate wifi.name item so it can scroll continuously.
source "$CONFIG_DIR/colors.sh"

if ipconfig getifaddr en0 >/dev/null 2>&1; then
  SSID="$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')"
  if [ -n "$SSID" ] && [ "$SSID" != "<redacted>" ]; then
    sketchybar --set "$NAME" icon=󰤨 icon.color=$BLUE icon.padding_right=4 \
               --set wifi.name drawing=on label="$SSID"
  else
    sketchybar --set "$NAME" icon=󰤨 icon.color=$BLUE icon.padding_right=6 \
               --set wifi.name drawing=off
  fi
else
  sketchybar --set "$NAME" icon=󰤮 icon.color=$SURFACE2 icon.padding_right=6 \
             --set wifi.name drawing=off
fi
