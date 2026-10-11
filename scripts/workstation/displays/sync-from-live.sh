#!/usr/bin/env bash
# Copy the live extension files into this directory and rewrite binding and command of
# every shortcut in keybindings.list from the live entry with that name (default), or
# only list what drifted (--check, exit 1 on drift). The other direction is restore.sh.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
check=false
[ "${1:-}" = --check ] && check=true
drift=0
mk=org.gnome.settings-daemon.plugins.media-keys

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

# gsettings prints strings quoted; strip the quotes for the list
unquote() { local v=$1; v=${v#\'}; echo "${v%\'}"; }

list="$here/keybindings.list" new=$(mktemp)
trap 'rm -f "$new"' EXIT
while IFS= read -r line; do
    case "$line" in ''|'#'*) echo "$line"; continue ;; esac
    name=${line%%|*} found=""
    for p in $(gsettings get "$mk" custom-keybindings | grep -o "'[^']*'" | tr -d "'"); do
        if [ "$(gsettings get "$mk.custom-keybinding:$p" name)" = "'$name'" ]; then
            found="$name|$(unquote "$(gsettings get "$mk.custom-keybinding:$p" binding)")|$(unquote "$(gsettings get "$mk.custom-keybinding:$p" command)")"
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

if $check; then
    [ "$drift" -eq 0 ] && echo "in sync" || exit 1
fi
