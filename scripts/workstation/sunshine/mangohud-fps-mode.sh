#!/usr/bin/env bash
# Switch the MangoHud FPS limit between streaming (fixed 60 Hz dummy plug)
# and desk use (75 Hz VRR monitor). Called by Sunshine's global_prep_cmd:
#   do   -> mangohud-fps-mode stream
#   undo -> mangohud-fps-mode desk
# MangoHud reloads its config on change, so running games pick it up live.
set -euo pipefail

case "${1:-}" in
    stream) limit=60; method=early ;;  # even pacing for fixed 60 Hz capture
    desk)   limit=72; method=late  ;;  # just below 75 Hz VRR ceiling, lowest latency
    *) echo "usage: ${0##*/} stream|desk" >&2; exit 2 ;;
esac

configs=()
while IFS= read -r -d '' f; do
    configs+=("$f")
done < <(find "$HOME/.var/app/io.github.benjamimgois.goverlay/data/goverlay/gameconfig" \
             -name MangoHud.conf -print0 2>/dev/null)
[ -f "$HOME/.config/MangoHud/MangoHud.conf" ] && configs+=("$HOME/.config/MangoHud/MangoHud.conf")

set_key() {  # set_key <file> <key> <value>: replace the line, or append it if missing
    if grep -q "^$2=" "$1"; then
        sed -i "s/^$2=.*/$2=$3/" "$1"
    else
        printf '%s=%s\n' "$2" "$3" >> "$1"
    fi
}

for f in "${configs[@]}"; do
    set_key "$f" fps_limit "$limit"
    set_key "$f" fps_limit_method "$method"
done

echo "mangohud-fps-mode: $1 -> fps_limit=$limit ($method) in ${#configs[@]} configs"
