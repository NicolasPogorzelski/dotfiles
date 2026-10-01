#!/usr/bin/env bash
# Display layouts for Sunshine streaming with portal capture.
# Portal consent is bound to one monitor, so the dummy plug (HDMI-1) must exist
# in every layout; only the desk monitor (DP-1) comes and goes.
#   desk        -> DP-1 primary + HDMI-1 as a second (invisible) monitor,
#                  left of DP-1 and shifted down so the two only share a
#                  221 px strip at the bottom-left edge of DP-1 (keeps the
#                  pointer from wandering onto the dummy)
#   stream      -> HDMI-1 only, primary (TV via Moonlight)
#   stream-both -> HDMI-1 primary, DP-1 stays on (fallback if the portal
#                  stream does not survive DP-1 being disabled)
#   kms-desk    -> DP-1 only (the pre-portal layout, for rollback to KMS capture)
set -euo pipefail

# gdctl is a Python script run by /usr/bin/python3. The Sunshine unit exports
# LD_LIBRARY_PATH=<homebrew>/lib, which makes the system interpreter load
# Homebrew's libpython and lose the system 'gi' module - so drop it for gdctl.
gdctl() { env -u LD_LIBRARY_PATH /usr/bin/gdctl "$@"; }

desk_mon=(--monitor DP-1 --mode 3440x1440@75.050+vrr)
dummy_mon=(--monitor HDMI-1 --mode 3840x2160@60.000 --color-mode bt2100 --scale 1)
# While streaming the dummy runs at 120 Hz: games stay capped at 60 FPS (MangoHud),
# so a missed compositor refresh costs 8.3 ms instead of 16.7 ms and the frame is
# usually still in place when Sunshine takes its next 60 FPS sample.
dummy_stream=(--monitor HDMI-1 --mode 3840x2160@120.000 --color-mode bt2100 --scale 1)

case "${1:-}" in
    desk)
        # Absolute positions: relative placement (--left-of) can only align
        # top edges, not reproduce the vertical offset.
        gdctl set --logical-monitor "${desk_mon[@]}" --primary --x 3840 --y 0 \
                  --logical-monitor "${dummy_mon[@]}" --x 0 --y 1219 ;;
    stream)
        gdctl set --logical-monitor "${dummy_stream[@]}" --primary ;;
    stream-both)
        gdctl set --logical-monitor "${dummy_mon[@]}" --primary \
                  --logical-monitor "${desk_mon[@]}" --left-of HDMI-1 ;;
    kms-desk)
        gdctl set --logical-monitor "${desk_mon[@]}" --primary ;;
    *) echo "usage: ${0##*/} desk|stream|stream-both|kms-desk" >&2; exit 2 ;;
esac

echo "sunshine-display-mode: $1"
