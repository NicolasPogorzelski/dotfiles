#!/usr/bin/env bash
# Switch the MangoHud FPS limit between streaming (fixed 60 Hz dummy plug)
# and desk use (75 Hz VRR monitor). Called by Sunshine's global_prep_cmd:
#   do   -> mangohud-fps-mode stream
#   undo -> mangohud-fps-mode desk
# MangoHud reloads its config on change, so running games pick it up live.
#
# The chosen mode is remembered in a state file. Goverlay (re)writes per-game
# configs with its own fps_limit (default 0 = unlimited) whenever a game is
# set up or patched, so mangohud-fps-sync.service runs "watch", which re-applies
# the remembered mode to every config that has drifted from it.
#   apply -> re-apply the remembered mode once
#   watch -> apply every few seconds, forever
set -euo pipefail

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/mangohud-fps-mode"
gameconfig_dir="$HOME/.var/app/io.github.benjamimgois.goverlay/data/goverlay/gameconfig"
global_config="$HOME/.config/MangoHud/MangoHud.conf"
watch_interval=2

settings_for() {  # settings_for <mode>: sets limit and method, fails on unknown mode
    case "$1" in
        stream) limit=60; method=early ;;  # even pacing for fixed 60 Hz capture
        desk)   limit=72; method=late  ;;  # just below 75 Hz VRR ceiling, lowest latency
        *) return 1 ;;
    esac
}

set_key() {  # set_key <file> <key> <value>: replace or append; returns 1 if already set
    if grep -qx "$2=$3" "$1"; then
        return 1
    elif grep -q "^$2=" "$1"; then
        sed -i "s/^$2=.*/$2=$3/" "$1"
    else
        printf '%s=%s\n' "$2" "$3" >> "$1"
    fi
}

apply_mode() {  # apply_mode <mode>: echoes every config it had to change
    local f changed
    local -a configs=()
    while IFS= read -r -d '' f; do
        configs+=("$f")
    done < <(find "$gameconfig_dir" -name MangoHud.conf -print0 2>/dev/null)
    [ -f "$global_config" ] && configs+=("$global_config")

    for f in "${configs[@]}"; do
        changed=0
        set_key "$f" fps_limit "$limit" && changed=1
        set_key "$f" fps_limit_method "$method" && changed=1
        [ "$changed" -eq 1 ] && echo "mangohud-fps-mode: $mode -> fps_limit=$limit ($method) in $f"
    done
    return 0
}

remembered_mode() {
    local m
    m=$(cat "$state_file" 2>/dev/null || true)
    settings_for "$m" && echo "$m" || echo desk  # no or broken state: assume desk
}

case "${1:-}" in
    stream|desk)
        mode=$1
        settings_for "$mode"
        mkdir -p "$(dirname "$state_file")"
        echo "$mode" > "$state_file"
        apply_mode
        echo "mangohud-fps-mode: now $mode (fps_limit=$limit, $method)" ;;
    apply)
        mode=$(remembered_mode)
        settings_for "$mode"
        apply_mode ;;
    watch)
        while true; do
            mode=$(remembered_mode)
            settings_for "$mode"
            apply_mode
            sleep "$watch_interval"
        done ;;
    *) echo "usage: ${0##*/} stream|desk|apply|watch" >&2; exit 2 ;;
esac
