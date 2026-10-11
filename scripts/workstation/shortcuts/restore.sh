#!/usr/bin/env bash
# Restore the GNOME custom shortcuts from keybindings.list (the reverse of
# sync-from-live.sh). Entries are matched by name: an existing entry is updated,
# a missing one is added in the next free customN slot. Runs again safely.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
mk=org.gnome.settings-daemon.plugins.media-keys
kb_base=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

# Paths of the existing custom shortcuts, one per line
kb_paths() { gsettings get "$mk" custom-keybindings | grep -o "'[^']*'" | tr -d "'"; }
kb() { gsettings "$1" "$mk.custom-keybinding:$2" "${@:3}"; }

while IFS='|' read -r name binding command; do
    case "$name" in ''|'#'*) continue ;; esac
    command=${command//@HOME@/$HOME}
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
