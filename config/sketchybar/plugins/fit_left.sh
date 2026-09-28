#!/bin/bash
# Keeps every gap left of the notch at 8pt:  [workspaces] [keep-awake] [stats] [clock]▮notch
# The clock is pinned to the notch, so the keep-awake pill takes whatever width is
# left and centres its icon + label inside it. Run after anything that changes the
# stats width or the keep-awake label.

ITEM=awake
GAP=8          # between pills
EDGE=12        # minimum padding inside the pill
ICON_W=13      # coffee icon width as SketchyBar measures it
ICON_GAP=5     # icon → label

rect() {
  sketchybar --query "$1" 2>/dev/null |
    jq -r '.bounding_rects["display-1"] // empty | "\(.origin[0] | floor) \(.size[0] | floor)"'
}

read -r WS_X WS_W <<<"$(rect workspaces)"
read -r _ ST_W <<<"$(rect stats)"
read -r CL_X _ <<<"$(rect clock)"
if [ -z "$WS_X" ] || [ -z "$ST_W" ] || [ -z "$CL_X" ]; then exit 0; fi

LABEL="$(sketchybar --query "$ITEM" | jq -r '.label.value')"
LABEL_W=$(awk -v n="${#LABEL}" 'BEGIN { print int(n * 7.8) }')   # JetBrains Mono 13pt

PILL_W=$(( CL_X - GAP - ST_W - GAP - (WS_X + WS_W + GAP) ))
FREE=$(( PILL_W - ICON_W - ICON_GAP - LABEL_W ))
(( FREE < 2 * EDGE )) && FREE=$(( 2 * EDGE ))
PAD_L=$(( FREE / 2 ))
PAD_R=$(( FREE - PAD_L ))

sketchybar --set "$ITEM" icon.padding_left="$PAD_L" icon.padding_right="$ICON_GAP" label.padding_right="$PAD_R"
