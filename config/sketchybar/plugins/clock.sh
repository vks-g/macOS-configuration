#!/bin/bash
# Time in bold blue, date in subtext (Quickshell clock box)
sketchybar --set "$NAME" icon="$(date '+%H:%M')" label="$(date '+%a %d %b')"
