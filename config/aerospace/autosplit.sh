#!/bin/bash
# Dwindle-style auto split (like Hyprland's default layout) for AeroSpace.
#
# AeroSpace puts a new window next to the focused one in the same container, so
# windows just pile up side by side. Dwindle instead splits the focused window's
# space in the other direction each time. In AeroSpace's tree that means:
#   - the 1st and 2nd tiled windows on a workspace sit side by side (root split)
#   - every later window is joined with the window it opened next to, which
#     creates a nested container in the opposite orientation
#       A | B   →   A | B/C   →   A | B/(C|D)   → ...
#
# Safety: only touches the new window, only when it's tiled (floating windows,
# dialogs and accordion layouts are left alone), skips windows AeroSpace finds
# while starting up (so existing layouts are never rearranged), and ignores
# every error. Remove the [[on-window-detected]] block that calls this script
# in aerospace.toml to turn it off.

WID="${AEROSPACE_WINDOW_ID:-}"
[ -n "$WID" ] || exit 0

# Don't rearrange anything while AeroSpace is (re)starting and detecting the
# windows that were already open.
AERO_PID="$(pgrep -ax AeroSpace | head -1)"  # -a: AeroSpace is our parent, which pgrep skips otherwise
[ -n "$AERO_PID" ] || exit 0
# macOS ps only has etime ([[dd-]hh:]mm:ss); convert it to seconds
UPTIME="$(ps -o etime= -p "$AERO_PID" 2>/dev/null | awk '{
  n = split($1, t, /[-:]/); s = 0; m[1] = 1; m[2] = 60; m[3] = 3600; m[4] = 86400
  for (i = n; i >= 1; i--) s += t[i] * m[n - i + 1]; print s }')"
[ -n "$UPTIME" ] && [ "$UPTIME" -lt 15 ] && exit 0

INFO="$(aerospace list-windows --all --format '%{window-id}|%{window-layout}|%{workspace}' 2>/dev/null |
        awk -F'|' -v id="$WID" '$1 == id { print $2 "|" $3; exit }')"
LAYOUT="${INFO%%|*}"
WS="${INFO#*|}"
[ -n "$INFO" ] || exit 0

# Only tiled windows; floating windows, dialogs and accordion layouts stay untouched
case "$LAYOUT" in
  h_tiles|v_tiles) ;;
  *) exit 0 ;;
esac

# 1 or 2 tiled windows on the workspace: keep the plain side-by-side split
TILED="$(aerospace list-windows --workspace "$WS" --format '%{window-layout}' 2>/dev/null |
         grep -c -E '^(h|v)_tiles$')"
[ "$TILED" -gt 2 ] || exit 0

# Join the new window with the one it opened next to (its left/upper neighbour),
# which splits that window's space in the opposite direction.
if [ "$LAYOUT" = "h_tiles" ]; then
  aerospace join-with --window-id "$WID" left 2>/dev/null ||
    aerospace join-with --window-id "$WID" right 2>/dev/null
else
  aerospace join-with --window-id "$WID" up 2>/dev/null ||
    aerospace join-with --window-id "$WID" down 2>/dev/null
fi
exit 0
