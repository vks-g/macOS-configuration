# macOS-configuration shell snippet — sourced from ~/.zshrc by install.sh.

# Quit AeroSpace (e.g. before proctoring/exam apps that don't work with it) and
# start it again. "enable off" first brings every hidden window back on screen.
alias aero-off='aerospace enable off; killall AeroSpace'
alias aero-on='open -a AeroSpace'

# Big, centred tty-clock in its own Ghostty window. tty-clock can't scale itself,
# so the window's font size sets the clock size: `clock` (28pt), `clock 40`, `clock 20`.
clock() {
  local size="${1:-28}" bin
  [[ "$size" == <-> ]] || { echo "usage: clock [font-size]"; return 1; }
  bin="$(command -v tty-clock)" || { echo "tty-clock isn't installed (brew install tty-clock)"; return 1; }
  osascript -e "tell application \"Ghostty\" to new window with configuration {font size:$size, command:\"$bin -c -C 2\"}" >/dev/null
}

# Live latency graph: router (teal) vs the internet (mauve), so lag reads as
# Wi-Fi or ISP at a glance. Extra hosts go on the same graph: `ping-graph google.com`.
ping-graph() {
  local router i
  local -a colors=('#94e2d5' '#cba6f7' '#f5c2e7' '#f9e2af') hosts args
  (( $+commands[gping] )) || { echo "gping isn't installed (brew install gping)"; return 1; }
  router="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')"
  hosts=(${router:+$router} 1.1.1.1 "$@")
  for i in {1..$#hosts}; do args+=(-c "${colors[i]:-white}"); done
  gping -n 1 -b 60 --clear "${args[@]}" "${hosts[@]}"
}
