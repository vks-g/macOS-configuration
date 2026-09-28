#!/bin/bash
# Keep-awake toggle: flips `pmset -a disablesleep` (click) and shows its state.
# ON  = the Mac never sleeps, even with the lid closed (peach, as a reminder).
# OFF = normal sleep.
# Toggling needs the sudo rule from helpers/sudoers-pmset.template, which
# install.sh can set up for you (it allows only these two
# exact pmset commands without a password). Reading the state needs nothing.

source "$CONFIG_DIR/colors.sh"

state() { pmset -g | awk '/SleepDisabled/ {print $2; exit}'; }

if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$(state)" = "1" ]; then NEW=0; else NEW=1; fi
  if ! sudo -n /usr/bin/pmset -a disablesleep "$NEW" >/dev/null 2>&1; then
    # No sudo rule installed (or it was removed): show it instead of failing silently
    sketchybar --set "$NAME" label="SUDO" label.color=$RED icon.color=$RED
    "$CONFIG_DIR/plugins/fit_left.sh"
    exit 0
  fi
fi

if [ "$(state)" = "1" ]; then
  sketchybar --set "$NAME" label="ON" label.color=$PEACH icon.color=$PEACH
else
  sketchybar --set "$NAME" label="OFF" label.color=$OVERLAY2 icon.color=$OVERLAY2
fi
"$CONFIG_DIR/plugins/fit_left.sh"
