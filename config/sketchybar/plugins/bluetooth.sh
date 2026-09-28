#!/bin/bash
# Power state + first connected device name (read-only; never toggles Bluetooth)
# The name lives in the separate bluetooth.name item so it can scroll continuously.
source "$CONFIG_DIR/colors.sh"

if [ "$(blueutil -p 2>/dev/null)" = "1" ]; then
  DEVICE="$(blueutil --connected 2>/dev/null | sed -n 's/.*name: "\([^"]*\)".*/\1/p' | head -1)"
  if [ -n "$DEVICE" ]; then
    sketchybar --set "$NAME" icon=󰂱 icon.color=$MAUVE icon.padding_right=4 \
               --set bluetooth.name drawing=on label="$DEVICE"
  else
    sketchybar --set "$NAME" icon=󰂯 icon.color=$MAUVE icon.padding_right=4 \
               --set bluetooth.name drawing=off
  fi
else
  sketchybar --set "$NAME" icon=󰂲 icon.color=$SURFACE2 icon.padding_right=4 \
             --set bluetooth.name drawing=off
fi
