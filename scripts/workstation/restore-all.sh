#!/usr/bin/env bash
# Restore the whole workstation: run restore.sh of every module (every directory next
# to this script that has one), in alphabetical order. A new module is picked up
# without touching this file.
#   restore-all.sh                  user part of every module
#   restore-all.sh --system         then the sudo part of every module that has one
#   restore-all.sh [--system] m...  only the named modules
# A failing module does not stop the others; the summary lists it and the exit code is 1.
# The module contract is in the README ("Workstation modules").
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
system=false
[ "${1:-}" = --system ] && { system=true; shift; }

modules=()
for d in "$here"/*/; do
    m=$(basename "$d")
    [ $# -gt 0 ] && [[ " $* " != *" $m "* ]] && continue
    [ -x "$d/restore.sh" ] && modules+=("$m")
done
[ ${#modules[@]} -gt 0 ] || { echo "no modules found${*:+ named $*}" >&2; exit 1; }

# A module has a sudo part if its restore.sh handles --system.
has_system() { grep -q -- '= --system' "$here/$1/restore.sh"; }

ok=() failed=() system_todo=()
for m in "${modules[@]}"; do
    echo "=== $m"
    if "$here/$m/restore.sh"; then ok+=("$m"); else failed+=("$m"); fi
    has_system "$m" && system_todo+=("$m")
done

if $system; then
    for m in "${system_todo[@]}"; do
        echo "=== $m --system"
        "$here/$m/restore.sh" --system || failed+=("$m --system")
    done
    system_todo=()
fi

echo
echo "=== Summary"
echo "restored: ${ok[*]:-none}"
[ ${#failed[@]} -eq 0 ] || echo "FAILED:   ${failed[*]} - see the output above, fix, run again"
[ ${#system_todo[@]} -eq 0 ] || echo "sudo part not run yet: ${system_todo[*]} -> $0 --system ${system_todo[*]}"
echo "Each module printed its own manual steps above (logins, passwords, pairing)."
[ ${#failed[@]} -eq 0 ]
