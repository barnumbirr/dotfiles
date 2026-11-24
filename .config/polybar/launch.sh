#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# The CPU temperature sensor, by name: hwmon numbers change between boots
for h in /sys/class/hwmon/hwmon*; do
  case $(cat "$h/name" 2>/dev/null) in
    coretemp | k10temp | zenpower) export HWMON_PATH="$h/temp1_input"; break ;;
  esac
done

# -r flag reloads polybar on config change
if command -v xrandr > /dev/null 2>&1; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload default &
  done
else
  polybar --reload default &
fi

echo "Bars launched..."
