#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Source: https://gitlab.dresrv.com/andrei/dotfiles/-/blob/sway-hidpi/dot_config/polybar/executable_launch.sh
# Find and set CPU package
# https://github.com/polybar/polybar/issues/2078
for i in /sys/class/hwmon/hwmon*/temp*_input; do
    name="$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*}))"
    if [ "$name" = "k10temp: Tctl" ]; then
        export HWMON_PATH="$i"
        break
    elif [ "$name" = "coretemp: Package id 0" ]; then
        export HWMON_PATH="$i"
        break
    fi
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
