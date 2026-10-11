#!/usr/bin/env bash
# Display layouts for Sunshine streaming with portal capture.
# Portal consent is bound to one monitor, so the dummy plug (HDMI-1) must exist
# in every layout; only the desk monitor (DP-1) comes and goes.
#   desk        -> DP-1 primary + HDMI-1 as a second (invisible) monitor,
#                  left of DP-1 and shifted down so the two only share a
#                  221 px strip at the bottom-left edge of DP-1 (keeps the
#                  pointer from wandering onto the dummy)
#   stream      -> HDMI-1 only, primary (TV via Moonlight)
#                  (non-16:9 client such as the Pixel 9 -> HDMI-1 in the
#                  client's exact mode if the patched EDID offers it,
#                  else the 4K120 layout)
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
# Phone mode: Moonlight on the Pixel 9 asks for 2251x1080 (native minus the
# camera cutout). That mode only exists while the dummy runs with the patched
# EDID (drm.edid_firmware); without it gdctl fails and the stream case falls
# back to dummy_stream. 16:9 clients (the Shield) never take this path.
dummy_phone() { echo --monitor HDMI-1 --mode "$1@120.000" --color-mode bt2100 --scale 1; }

case "${1:-}" in
    desk)
        # Absolute positions: relative placement (--left-of) can only align
        # top edges, not reproduce the vertical offset.
        gdctl set --logical-monitor "${desk_mon[@]}" --primary --x 3840 --y 0 \
                  --logical-monitor "${dummy_mon[@]}" --x 0 --y 1219 ;;
    stream)
        client="${SUNSHINE_CLIENT_WIDTH:-}x${SUNSHINE_CLIENT_HEIGHT:-}"
        logger -t sunshine-display-mode "client ${SUNSHINE_CLIENT_NAME:-?}: ${client}@${SUNSHINE_CLIENT_FPS:-?} hdr=${SUNSHINE_CLIENT_HDR:-?}"
        w=${SUNSHINE_CLIENT_WIDTH:-0} h=${SUNSHINE_CLIENT_HEIGHT:-0}
        if (( w > 0 && h > 0 && w * 9 != h * 16 )) &&
           gdctl set --logical-monitor $(dummy_phone "$client") --primary; then
            logger -t sunshine-display-mode "client $client -> native phone mode"
        else
            gdctl set --logical-monitor "${dummy_stream[@]}" --primary
        fi ;;
    stream-both)
        gdctl set --logical-monitor "${dummy_mon[@]}" --primary \
                  --logical-monitor "${desk_mon[@]}" --left-of HDMI-1 ;;
    kms-desk)
        gdctl set --logical-monitor "${desk_mon[@]}" --primary ;;
    *) echo "usage: ${0##*/} desk|stream|stream-both|kms-desk" >&2; exit 2 ;;
esac

echo "sunshine-display-mode: $1"
