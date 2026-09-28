#!/bin/bash
source "$CONFIG_DIR/colors.sh"

BATT="$(pmset -g batt)"
PERCENTAGE="$(grep -Eo '[0-9]+%' <<<"$BATT" | head -1 | tr -d '%')"
[ -z "$PERCENTAGE" ] && exit 0

case "$PERCENTAGE" in
  9[0-9]|100) ICON=󰁹 ;;
  [7-8][0-9]) ICON=󰂁 ;;
  [5-6][0-9]) ICON=󰁿 ;;
  [3-4][0-9]) ICON=󰁽 ;;
  [1-2][0-9]) ICON=󰁻 ;;
  *)          ICON=󰂎 ;;
esac

COLOR=$GREEN
[ "$PERCENTAGE" -lt 30 ] && COLOR=$YELLOW
[ "$PERCENTAGE" -lt 15 ] && COLOR=$RED

if grep -q 'AC Power' <<<"$BATT"; then
  ICON=󰂄
  COLOR=$SAPPHIRE
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$COLOR label="${PERCENTAGE}%"
