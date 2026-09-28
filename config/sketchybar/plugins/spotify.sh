#!/bin/bash
# Spotify pill. Reads Spotify's own playback notification ($INFO) — no polling.
# Falls back to asking Spotify directly (only if it's already running).

source "$CONFIG_DIR/colors.sh"
ITEMS=(spotify.track spotify.title spotify.prev spotify.play spotify.next)

hide() {
  args=(); for i in "${ITEMS[@]}"; do args+=(--set "$i" drawing=off); done
  sketchybar "${args[@]}"
  exit 0
}

if [ "$SENDER" = "spotify_change" ] && [ -n "$INFO" ]; then
  STATE="$(jq -r '."Player State" // empty' <<<"$INFO")"
  TITLE="$(jq -r '.Name // empty' <<<"$INFO")"
  ARTIST="$(jq -r '.Artist // empty' <<<"$INFO")"
else
  pgrep -xq Spotify || hide
  STATE="$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)"
  TITLE="$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)"
  ARTIST="$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)"
fi

STATE="$(tr '[:upper:]' '[:lower:]' <<<"$STATE")"
if [ "$STATE" = "stopped" ] || [ -z "$TITLE" ]; then
  hide
fi

if [ "$STATE" = "playing" ]; then PLAY_ICON=󰏤; else PLAY_ICON=󰐊; fi

LABEL="$TITLE"
[ -n "$ARTIST" ] && LABEL="$TITLE · $ARTIST"

sketchybar --set spotify.track drawing=on \
           --set spotify.title drawing=on label="$LABEL" \
           --set spotify.prev drawing=on \
           --set spotify.play drawing=on icon="$PLAY_ICON" \
           --set spotify.next drawing=on
