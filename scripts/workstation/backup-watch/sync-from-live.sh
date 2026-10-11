#!/usr/bin/env bash
# Copy the live backup reminder files into this directory (default), or only list what
# drifted (--check, exit 1 on drift). The other direction is restore.sh.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
check=false
[ "${1:-}" = --check ] && check=true
drift=0

while IFS='|' read -r rel live; do
    case "$rel" in ''|'#'*) continue ;; esac
    src="$HOME/$live" dst="$here/$rel"
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
done < "$here/files.list"

if $check; then
    [ "$drift" -eq 0 ] && echo "in sync" || exit 1
fi
