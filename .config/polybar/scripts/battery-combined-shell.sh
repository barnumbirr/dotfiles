#!/bin/sh

ac=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)
battery_level=0
battery_max=0
for b in /sys/class/power_supply/BAT*; do
    [ -f "$b/energy_full" ] || continue
    battery_level=$((battery_level + $(cat "$b/energy_now")))
    battery_max=$((battery_max + $(cat "$b/energy_full")))
done

if [ "$battery_max" -eq 0 ]; then
    echo "No battery"
    exit 0
fi

battery_percent=$((battery_level * 100 / battery_max))

if [ "$ac" -eq 1 ]; then
    icon=""

    if [ "$battery_percent" -gt 98 ]; then
        echo "$icon Charged"
    else
        echo "$icon $battery_percent %"
    fi
else
    if  [ "$battery_percent" -gt 90 ]; then
        icon=""
    elif [ "$battery_percent" -gt 75 ]; then
        icon=""
    elif [ "$battery_percent" -gt 50 ]; then
        icon=""
    elif [ "$battery_percent" -gt 25 ]; then
        icon=""
    elif [ "$battery_percent" -gt 10 ]; then
        icon=""
    else
        icon=""
    fi

    echo "$icon $battery_percent %"
fi

