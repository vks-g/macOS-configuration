# macOS-configuration shell snippet — sourced from ~/.zshrc by install.sh.

# Quit AeroSpace (e.g. before proctoring/exam apps that don't work with it) and
# start it again. "enable off" first brings every hidden window back on screen.
alias aero-off='aerospace enable off; killall AeroSpace'
alias aero-on='open -a AeroSpace'
