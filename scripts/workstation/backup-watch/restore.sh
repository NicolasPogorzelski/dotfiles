#!/usr/bin/env bash
# Restore the daily backup reminder (the reverse of sync-from-live.sh): script and units
# from files.list, then the timer. Expects the repo at ~/git/dotfiles (or $DOTFILES_DIR).
# Runs again safely. Live files that would change are kept as <file>.bak-<date>.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%F)

while IFS='|' read -r rel live; do
    case "$rel" in ''|'#'*) continue ;; esac
    src="$here/$rel" dst="$HOME/$live"
    if [ -f "$dst" ]; then
        cmp -s "$src" "$dst" && continue
        cp -p "$dst" "$dst.bak-$stamp"
    fi
    install -D -m "$(stat -c %a "$src")" "$src" "$dst"
    echo "restored: $dst"
done < "$here/files.list"

systemctl --user daemon-reload
systemctl --user enable --now backup-watch.timer
