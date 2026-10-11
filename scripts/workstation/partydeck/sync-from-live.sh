#!/usr/bin/env bash
# Copy the live PartyDeck setup into this directory (default), or only list what
# drifted (--check, exit 1 on drift). The other direction is restore.sh.
# Text files get the home directory replaced by @HOME@. settings.json is stored with
# gamescope_sdl_backend=false: PartyDeck's GUI keeps writing true back, and gamescope
# on the SDL (XWayland) backend flickers with black tiles here; the Wayland backend does not.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
check=false
[ "${1:-}" = --check ] && check=true
drift=0
home_real=$(readlink -f "$HOME")
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# normalize <live file> <repo name> -> what the repo should hold, on stdout
normalize() {
    if grep -qI . "$1"; then
        sed -e "s|$home_real|@HOME@|g" -e "s|$HOME|@HOME@|g" "$1" |
            if [ "$2" = settings.json ]; then jq --indent 2 '.gamescope_sdl_backend = false'; else cat; fi
    else
        cat "$1"
    fi
}

while IFS='|' read -r rel live; do
    case "$rel" in ''|'#'*) continue ;; esac
    src="$HOME/$live" dst="$here/$rel"
    if [ ! -f "$src" ]; then
        echo "missing live: $src"; drift=1; continue
    fi
    normalize "$src" "$rel" > "$tmp"
    cmp -s "$tmp" "$dst" && continue
    drift=1
    if $check; then
        echo "drifted: $rel"
    else
        install -D -m "$(stat -c %a "$src")" "$tmp" "$dst"
        echo "updated: $rel"
    fi
done < "$here/files.list"

if $check; then
    [ "$drift" -eq 0 ] && echo "in sync" || exit 1
fi
