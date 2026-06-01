#!/usr/bin/env bash
# terminate already running instances
killall -q polybar
# wait until processes shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
# giv xorg/i3 time to map screens (on cold boot)
sleep 0.5
# launch polybar, using defaults inc
# ~/.config/polybar/config.ini
polybar example 2>&1 | tee -a /tmp/polybar.log & disown
#polybar example &

