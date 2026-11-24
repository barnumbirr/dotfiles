#!/bin/sh

# Sum remaining charge across all batteries and report AC state.
# Detects AC and battery path names dynamically, and falls back
# from charge_* (ACPI) to energy_* (older firmware).

ac_path=""
batteries=""

for dir in /sys/class/power_supply/*/; do
    case "$(cat "${dir}type" 2>/dev/null)" in
        Mains)    [ -z "$ac_path" ] && ac_path="${dir%/}" ;;
        Battery)  batteries="$batteries ${dir%/}" ;;
    esac
done

ac=0
[ -r "$ac_path/online" ] && ac=$(cat "$ac_path/online")

battery_level=0
battery_max=0
for bat in $batteries; do
    if [ -r "$bat/charge_now" ] && [ -r "$bat/charge_full" ]; then
        battery_level=$((battery_level + $(cat "$bat/charge_now")))
        battery_max=$((battery_max + $(cat "$bat/charge_full")))
    elif [ -r "$bat/energy_now" ] && [ -r "$bat/energy_full" ]; then
        battery_level=$((battery_level + $(cat "$bat/energy_now")))
        battery_max=$((battery_max + $(cat "$bat/energy_full")))
    fi
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

