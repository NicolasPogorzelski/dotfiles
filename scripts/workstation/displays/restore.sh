#!/usr/bin/env bash
# Restore the display helpers on a fresh Bazzite install (the reverse of sync-from-live.sh):
# the Fenster-Heimholer extension from files.list (schema compiled, extension enabled).
# Runs again safely. The Super+Alt+D shortcut lives in ../shortcuts.
# Live files that would change are kept as <file>.bak-<date>.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%F)
uuid=window-heimholer@nicolas
ext="$HOME/.local/share/gnome-shell/extensions/$uuid"

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

glib-compile-schemas "$ext/schemas"

enabled=$(gsettings get org.gnome.shell enabled-extensions)
case "$enabled" in
    *"'$uuid'"*) ;;
    '@as []'|'[]') gsettings set org.gnome.shell enabled-extensions "['$uuid']" ;;
    *) gsettings set org.gnome.shell enabled-extensions "${enabled%]}, '$uuid']" ;;
esac

echo "Done. Log out and in once: GNOME on Wayland loads a new extension only at login."
echo "Then check: gnome-extensions info $uuid   (State: ACTIVE)"
