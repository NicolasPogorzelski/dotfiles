#!/usr/bin/env bash
# Rewrite binding and command of every shortcut in keybindings.list from the live entry
# with that name (default), or only list what drifted (--check, exit 1 on drift). Live
# shortcuts that the list does not name are reported, not added: the list decides what is
# backed up, so add a new one by name first. The other direction is restore.sh.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
check=false
[ "${1:-}" = --check ] && check=true
drift=0
mk=org.gnome.settings-daemon.plugins.media-keys
home_real=$(readlink -f "$HOME")

# gsettings prints strings quoted; strip the quotes for the list
unquote() { local v=$1; v=${v#\'}; echo "${v%\'}"; }
paths=$(gsettings get "$mk" custom-keybindings | grep -o "'[^']*'" | tr -d "'")

list="$here/keybindings.list" new=$(mktemp)
trap 'rm -f "$new"' EXIT
while IFS= read -r line; do
    case "$line" in ''|'#'*) echo "$line"; continue ;; esac
    name=${line%%|*} found=""
    for p in $paths; do
        if [ "$(gsettings get "$mk.custom-keybinding:$p" name)" = "'$name'" ]; then
            command=$(unquote "$(gsettings get "$mk.custom-keybinding:$p" command)")
            command=${command//$home_real/@HOME@}
            command=${command//$HOME/@HOME@}
            found="$name|$(unquote "$(gsettings get "$mk.custom-keybinding:$p" binding)")|$command"
            break
        fi
    done
    if [ -z "$found" ]; then
        echo "missing live shortcut: $name" >&2; drift=1; echo "$line"
    else
        echo "$found"
    fi
done < "$list" > "$new"
if ! cmp -s "$new" "$list"; then
    drift=1
    if $check; then
        echo "drifted: keybindings.list"; diff "$list" "$new" || true
    else
        cp "$new" "$list"; echo "updated: keybindings.list"
    fi
fi

for p in $paths; do
    name=$(unquote "$(gsettings get "$mk.custom-keybinding:$p" name)")
    awk -F'|' -v n="$name" '$1 == n { f = 1 } END { exit !f }' "$list" ||
        { echo "not backed up: live shortcut \"$name\" - add it to keybindings.list"; drift=1; }
done

if $check; then
    [ "$drift" -eq 0 ] && echo "in sync" || exit 1
fi
