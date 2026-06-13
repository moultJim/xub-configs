#!/usr/bin/env bash
# terminate already running instances
killall -q polybar
# wait until processes shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
# giv xorg/i3 time to map screens (on cold boot)
sleep 1
# Clear the old log file (or create it if it doesn't exist)
> /tmp/polybar.log
# launch
polybar example 2>&1 | tee -a /tmp/polybar.log & disown

