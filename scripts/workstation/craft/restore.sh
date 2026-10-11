#!/usr/bin/env bash
# Restore the storytold Craft apps and their auto-updater on a fresh Bazzite install
# (the reverse of sync-from-live.sh): updater script and timer from files.list, then
# every app in apps.list in its latest GitHub release (SHA256-checked by the updater),
# then the weekly timer. Runs again safely: present apps are only updated.
# Live files that would change are kept as <file>.bak-<date>.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%F)

for cmd in flatpak curl jq flock sha256sum; do
    command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 1; }
done

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

# The bundles pull their runtime (org.freedesktop.Platform) from Flathub; a --user
# install looks for it in the user installation's remotes.
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

mapfile -t apps < <(grep -vE '^[[:space:]]*(#|$)' "$here/apps.list")
"$HOME/.local/bin/craft-flatpak-update" "${apps[@]}" ||
    echo "WARNING: some apps failed, see the output above; run restore.sh again" >&2

systemctl --user daemon-reload
systemctl --user enable --now craft-flatpak-update.timer

echo
echo "Done. Installed:"
flatpak list --user --app --columns=application,version | grep '^ai\.storyteller\.' || true
systemctl --user list-timers craft-flatpak-update.timer --no-pager
