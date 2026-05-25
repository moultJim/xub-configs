#!/usr/bin/env bash
# terminate already running instances
killall -q polybar
# wait until processes shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
# launch polybar, using defaults in
# ~/.config/polybar/config.ini
polybar example &

