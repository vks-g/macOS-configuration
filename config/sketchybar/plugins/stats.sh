#!/bin/bash
# CPU busy %, RAM used/total in GB (Activity Monitor's "Memory Used") and CPU temp.
# One local macmon sample (no sudo, no network), then one sketchybar update.

source "$CONFIG_DIR/colors.sh"

JSON="$(macmon pipe -s 1 -i 500 2>/dev/null)"
[ -z "$JSON" ] && exit 0

read -r CPU RAM_PCT RAM_USED RAM_TOTAL TEMP <<<"$(jq -r '[
    (.cpu_active_ratio * 100 | round),
    (.memory.ram_usage / .memory.ram_total * 100 | round),
    (.memory.ram_usage / 1073741824 | round),
    (.memory.ram_total / 1073741824 | round),
    (.temp.cpu_temp_avg | round)
  ] | @tsv' <<<"$JSON")"

level_color() { # value warn crit normal
  if [ "$1" -ge "$3" ]; then echo $RED
  elif [ "$1" -ge "$2" ]; then echo $YELLOW
  else echo "$4"; fi
}

sketchybar --set stats.cpu  label="${CPU}%"  icon.color=$(level_color "$CPU" 70 90 $SAPPHIRE) \
           --set stats.ram  label="${RAM_USED}G/${RAM_TOTAL}G" icon.color=$(level_color "$RAM_PCT" 80 90 $GREEN) \
           --set stats.temp label="${TEMP}°" icon.color=$(level_color "$TEMP" 70 85 $PEACH)

# The stats pill may have changed width; re-fit the app pill
"$CONFIG_DIR/plugins/fit_left.sh"
