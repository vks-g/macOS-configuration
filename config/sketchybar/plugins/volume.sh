#!/bin/bash
source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
fi
MUTED="$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)"
[ -z "$VOLUME" ] || [ "$VOLUME" = "missing value" ] && exit 0

case "$VOLUME" in
  [6-9][0-9]|100) ICON=󰕾 ;;
  [3-5][0-9])     ICON=󰖀 ;;
  [1-9]|[1-2][0-9]) ICON=󰕿 ;;
  *)              ICON=󰖁 ;;
esac

if [ "$MUTED" = "true" ]; then
  sketchybar --set "$NAME" icon=󰖁 icon.color=$OVERLAY0 label="${VOLUME}%" label.color=$OVERLAY0
else
  sketchybar --set "$NAME" icon="$ICON" icon.color=$TEXT label="${VOLUME}%" label.color=$TEXT
fi
