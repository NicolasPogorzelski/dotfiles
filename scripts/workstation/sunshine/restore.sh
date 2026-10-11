#!/usr/bin/env bash
# Restore the Sunshine/Moonlight setup of the Bazzite gaming PC from this
# directory (the reverse of sync-from-live.sh).
#   restore.sh          user part: scripts, units, configs, MangoHud, enable services
#   restore.sh --edid   system part (sudo): patched dummy EDID for the Pixel 9 native
#                       mode as kernel arguments; needs a reboot afterwards
# Live files that would change are kept as <file>.bak-<date>. What cannot come
# from a public repo (password, paired clients, screen-share grant) is printed
# at the end as manual steps.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%F)
edid=/etc/firmware/edid/llv-phone.bin

restore_edid() {
    sudo install -D -m 644 "$here/edid/llv-phone.bin" "$edid"
    rpm-ostree initramfs-etc | grep -qx "  $edid" ||
        sudo rpm-ostree initramfs-etc --track="$edid"
    local karg args=()
    for karg in firmware_class.path=/etc/firmware drm.edid_firmware=HDMI-A-1:edid/llv-phone.bin; do
        grep -qw -- "$karg" /proc/cmdline || args+=(--append="$karg")
    done
    [ ${#args[@]} -gt 0 ] && sudo rpm-ostree kargs "${args[@]}"
    echo "EDID set up. Reboot, then check (no output = loaded):"
    echo "  cmp /sys/class/drm/card1-HDMI-A-1/edid $here/edid/llv-phone.bin"
}

if [ "${1:-}" = --edid ]; then
    restore_edid
    exit 0
fi

[ -x /home/linuxbrew/.linuxbrew/opt/sunshine/bin/sunshine ] ||
    echo "WARNING: Sunshine is not installed yet: brew install lizardbyte/homebrew/sunshine" >&2
command -v mangohud >/dev/null || echo "WARNING: mangohud not found" >&2

while IFS='|' read -r rel live; do
    case "$rel" in ''|'#'*) continue ;; esac
    src="$here/$rel" dst="$HOME/$live"
    if [ -f "$dst" ]; then
        cmp -s "$src" "$dst" && continue
        cp -p "$dst" "$dst.bak-$stamp"
    fi
    install -D -m "$(stat -c %a "$src")" "$src" "$dst"
    echo "restored: ~/$live"
done < "$here/files.list"

systemctl --user daemon-reload
systemctl --user enable app-dev.lizardbyte.app.Sunshine.service sunshine-session-watch.service
systemctl --user enable --now mangohud-fps-sync.service
"$HOME/.local/bin/sunshine-display-mode" desk || echo "desk layout failed - dummy plug connected?" >&2

cat <<EOF

User part done. Still to do by hand:
 1. EDID for the Pixel 9 native mode, if not done yet: $0 --edid, then reboot
 2. systemctl --user restart app-dev.lizardbyte.app.Sunshine.service
    -> GNOME asks which screen to share: pick "LLV 27\"", allow remote interaction
 3. https://localhost:47990: set the web UI user/password, pair the Shield and the Pixel again
 4. Store that password for the session watcher (README, "sunshine-session-watch"):
    install -d -m 700 ~/.config/sunshine-session-watch
    systemd-ask-password -n "Sunshine web UI password:" | systemd-creds encrypt --user --name=sunshine-api - ~/.config/sunshine-session-watch/api.cred
    systemctl --user restart sunshine-session-watch.service
EOF
