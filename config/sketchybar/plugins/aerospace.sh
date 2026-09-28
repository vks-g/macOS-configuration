#!/bin/bash
# Repaints the workspace pills. Mirrors Quickshell states:
# active = mauve pill, occupied = surface1 pill + blue number, empty = dim number.
# Shows workspaces 1-8 like the Arch bar (SEQ_END=8); 9-10 stay reachable by key
# but aren't drawn, so the left side never runs into the clock beside the notch.

source "$CONFIG_DIR/colors.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
OCCUPIED=" $(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ') "

args=()
for sid in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$sid" -gt 8 ]; then
    args+=(--set ws.$sid drawing=off)
  elif [ "$sid" = "$FOCUSED" ]; then
    args+=(--set ws.$sid drawing=on background.drawing=on background.color=$MAUVE icon.color=$BASE)
  elif [[ "$OCCUPIED" == *" $sid "* ]]; then
    args+=(--set ws.$sid drawing=on background.drawing=on background.color=$SURFACE1 icon.color=$BLUE)
  else
    args+=(--set ws.$sid drawing=on background.drawing=off icon.color=$SURFACE2)
  fi
done

sketchybar "${args[@]}"
