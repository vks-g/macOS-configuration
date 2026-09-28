#!/bin/bash
# Opens the real macOS Control Center.
# Needs (once): Accessibility for sketchybar + permission to control System Events.
osascript <<'APPLESCRIPT'
tell application "System Events" to tell process "ControlCenter"
  set ccItems to (menu bar items of menu bar 1 whose description is "Control Center")
  if ccItems is {} then set ccItems to (menu bar items of menu bar 1 whose name is "Control Center")
  click item 1 of ccItems
end tell
APPLESCRIPT
