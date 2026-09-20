#!/bin/bash
set -euo pipefail

# udev passes the transition explicitly.  The no-argument form is used by the
# boot-time systemd unit so the current AC state is read rather than inferred.
case "${1:-}" in
    ac)
        target="100%"
        ;;
    battery)
        target="30%"
        ;;
    "")
        ac_online_file=/sys/class/power_supply/AC/online
        if [[ ! -r "$ac_online_file" ]]; then
            printf 'Cannot determine AC power state: %s is unavailable.\n' "$ac_online_file" >&2
            exit 1
        fi

        if [[ "$(<"$ac_online_file")" == "1" ]]; then
            target="100%"
        else
            target="30%"
        fi
        ;;
    *)
        printf 'Usage: %s [ac|battery]\n' "$0" >&2
        exit 2
        ;;
esac

/usr/bin/brightnessctl --class=backlight set "$target"
