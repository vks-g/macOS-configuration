#!/bin/bash
# Repaints the workspace pills. Mirrors Quickshell states:
# active = mauve pill; every other workspace uses the same dark translucent pill as
# the rest of the bar (PILL_BG + faint border): blue number = has windows, dim = empty.
# There are 10 workspaces but only 8 pills (VISIBLE), so the left side never runs
# into the clock beside the notch. The 8 slide like a window: going past the last
# shown pill jumps to 3-10, going before the first jumps back to 1-8, and moving
# inside the window leaves it where it is. Every pill has the same width, so the
# group never changes size.

source "$CONFIG_DIR/colors.sh"

TOTAL=10
VISIBLE=8

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
OCCUPIED=" $(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ') "

# The window currently shown starts at the first drawn pill
START=1
for (( sid = 1; sid <= TOTAL - VISIBLE + 1; sid++ )); do
  if [ "$(sketchybar --query ws.$sid 2>/dev/null | jq -r '.geometry.drawing')" = "on" ]; then
    START=$sid; break
  fi
done

if [[ "$FOCUSED" =~ ^[0-9]+$ ]]; then
  if (( FOCUSED < START )); then START=1
  elif (( FOCUSED >= START + VISIBLE )); then START=$(( TOTAL - VISIBLE + 1 ))
  fi
fi
END=$(( START + VISIBLE - 1 ))

args=()
for (( sid = 1; sid <= TOTAL; sid++ )); do
  if (( sid < START || sid > END )); then
    args+=(--set ws.$sid drawing=off)
  elif [ "$sid" = "$FOCUSED" ]; then
    args+=(--set ws.$sid drawing=on background.drawing=on background.color=$MAUVE background.border_width=0 icon.color=$BASE)
  elif [[ "$OCCUPIED" == *" $sid "* ]]; then
    args+=(--set ws.$sid drawing=on background.drawing=on background.color=$WS_BG background.border_width=1 background.border_color=$PILL_BORDER icon.color=$BLUE)
  else
    args+=(--set ws.$sid drawing=on background.drawing=on background.color=$WS_BG background.border_width=1 background.border_color=$PILL_BORDER icon.color=$SURFACE2)
  fi
done

sketchybar "${args[@]}"
