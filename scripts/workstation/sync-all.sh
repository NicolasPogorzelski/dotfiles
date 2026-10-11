#!/usr/bin/env bash
# Back up the whole workstation: run sync-from-live.sh of every module (every directory
# next to this script that has one). A new module is picked up without touching this file.
#   sync-all.sh            copy what changed live into the repo; review and commit afterwards
#   sync-all.sh --check    only report drift, change nothing; exit 1 if any module drifted
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
args=()
[ "${1:-}" = --check ] && args=(--check)

clean=() drifted=()
for d in "$here"/*/; do
    m=$(basename "$d")
    [ -x "$d/sync-from-live.sh" ] || continue
    echo "=== $m"
    if "$d/sync-from-live.sh" "${args[@]}"; then clean+=("$m"); else drifted+=("$m"); fi
done

echo
echo "=== Summary"
echo "in sync: ${clean[*]:-none}"
if [ ${#drifted[@]} -gt 0 ]; then
    if [ ${#args[@]} -gt 0 ]; then
        echo "DRIFTED: ${drifted[*]} -> run $0 without --check, review, commit"
    else
        echo "FAILED:  ${drifted[*]} - see the output above"
    fi
    exit 1
fi
[ ${#args[@]} -gt 0 ] || echo "Now review with git diff and commit."
