#!/usr/bin/env bash
# Copy the live Sunshine/Moonlight setup into this directory (default), or
# only list what drifted (--check, exit 1 on drift). Covers files.list
# (under $HOME), system.list (absolute paths, world-readable, so no sudo)
# and the values in gsettings.list. The other direction is restore.sh.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
check=false
[ "${1:-}" = --check ] && check=true
drift=0

# validate.sh check 5 refuses lists that name one of Sunshine's secrets: stop
# before anything is copied into the (public) repo.
if ! (cd "$here/../../.." && ./validate.sh > /dev/null); then
    echo "validate.sh failed - run it from the repo root to see why; nothing copied" >&2
    exit 1
fi

sync_list() {  # sync_list <list> <prefix for the live path>
    local rel live src dst
    while IFS='|' read -r rel live; do
        case "$rel" in ''|'#'*) continue ;; esac
        src="$2$live" dst="$here/$rel"
        if [ ! -f "$src" ]; then
            echo "missing live: $src"; drift=1; continue
        fi
        cmp -s "$src" "$dst" && continue
        drift=1
        if $check; then
            echo "drifted: $rel"
        else
            install -D -m "$(stat -c %a "$src")" "$src" "$dst"
            echo "updated: $rel"
        fi
    done < "$here/$1"
}

sync_list files.list "$HOME/"
sync_list system.list ""

gs="$here/gsettings.list" new=$(mktemp)
trap 'rm -f "$new"' EXIT
while IFS= read -r line; do
    case "$line" in ''|'#'*) echo "$line"; continue ;; esac
    read -r schema key _ <<<"$line"
    echo "$schema $key $(gsettings get "$schema" "$key")"
done < "$gs" > "$new"
if ! cmp -s "$new" "$gs"; then
    drift=1
    if $check; then echo "drifted: gsettings.list"; else cp "$new" "$gs"; echo "updated: gsettings.list"; fi
fi

if $check; then
    [ "$drift" -eq 0 ] && echo "in sync" || exit 1
fi
