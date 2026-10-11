#!/usr/bin/env bash
# Restore the display helpers on a fresh Bazzite install (the reverse of sync-from-live.sh):
# the Fenster-Heimholer extension from files.list (schema compiled, extension enabled) and
# the custom shortcuts from keybindings.list. Runs again safely.
# Live files that would change are kept as <file>.bak-<date>.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%F)
uuid=window-heimholer@nicolas
ext="$HOME/.local/share/gnome-shell/extensions/$uuid"
mk=org.gnome.settings-daemon.plugins.media-keys
kb_base=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

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

# Paths of the existing custom shortcuts, one per line
kb_paths() { gsettings get "$mk" custom-keybindings | grep -o "'[^']*'" | tr -d "'"; }
kb() { gsettings "$1" "$mk.custom-keybinding:$2" "${@:3}"; }

while IFS='|' read -r name binding command; do
    case "$name" in ''|'#'*) continue ;; esac
    path=""
    for p in $(kb_paths); do
        [ "$(kb get "$p" name)" = "'$name'" ] && { path=$p; break; }
    done
    if [ -z "$path" ]; then
        n=0
        while kb_paths | grep -qx "$kb_base/custom$n/"; do n=$((n+1)); done
        path="$kb_base/custom$n/"
        list=$(gsettings get "$mk" custom-keybindings)
        case "$list" in
            '@as []'|'[]') gsettings set "$mk" custom-keybindings "['$path']" ;;
            *) gsettings set "$mk" custom-keybindings "${list%]}, '$path']" ;;
        esac
    fi
    kb set "$path" name "$name"
    kb set "$path" binding "$binding"
    kb set "$path" command "$command"
    echo "shortcut: $binding -> $name"
done < "$here/keybindings.list"

echo
echo "Done. Log out and in once: GNOME on Wayland loads a new extension only at login."
echo "Then check: gnome-extensions info $uuid   (State: ACTIVE)"
