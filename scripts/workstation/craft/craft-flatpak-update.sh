#!/usr/bin/bash
# Update the storytold Craft Flatpak bundles (ai.storyteller.*) from their GitHub releases.
#   craft-flatpak-update              update every installed ai.storyteller.* app
#   craft-flatpak-update <name>...    the same, and install <name> (e.g. wordcraft) if missing
# Bundles have no update source, so compare the version with the GitHub API, download the
# asset, check it against the release's SHA256SUMS.txt and install it over the old one.
# Started by craft-flatpak-update.timer (systemd --user); restore.sh calls it with apps.list.
set -uo pipefail

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/craft-flatpak-update.lock"
flock -n 9 || { echo "laeuft bereits"; exit 0; }

# right after boot, wait a little for the network (user units cannot wait for network-online.target)
for _ in $(seq 30); do
    curl -fsS -o /dev/null --max-time 5 https://api.github.com && break
    sleep 10
done

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
updated=() failed=()

wanted=$(flatpak list --user --app --columns=application | sed -n 's/^ai\.storyteller\.//p')
for name in "$@"; do
    [[ $name =~ ^[a-z0-9-]+$ ]] || { echo "$name: ungueltiger Name"; failed+=("$name"); continue; }
    wanted+=$'\n'"$name"
done

for name in $(sort -u <<<"$wanted"); do
    app="ai.storyteller.$name"
    cur=$(flatpak info --user "$app" 2>/dev/null | awk -F': *' '/^ *Version:/ {print $2}')
    rel=$(curl -fsSL --max-time 30 "https://api.github.com/repos/storytold/$name/releases/latest") \
        || { echo "$name: GitHub-API nicht erreichbar"; failed+=("$name"); continue; }
    new=$(jq -r '.tag_name | ltrimstr("v")' <<<"$rel")
    if [ -z "$new" ] || [ "$(printf '%s\n%s\n' "$cur" "$new" | sort -V | tail -1)" = "$cur" ]; then
        echo "$name: aktuell ($cur)"
        continue
    fi

    file="$name-$new-linux-x86_64.flatpak"
    url=$(jq -r --arg f "$file" '.assets[] | select(.name==$f) | .browser_download_url' <<<"$rel")
    sums=$(jq -r '.assets[] | select(.name=="SHA256SUMS.txt") | .browser_download_url' <<<"$rel")
    if [ -z "$url" ] || [ -z "$sums" ]; then
        echo "$name: $new hat kein $file/SHA256SUMS.txt"; failed+=("$name"); continue
    fi

    echo "$name: ${cur:-nicht installiert} -> $new"
    if ! curl -fsSL --max-time 600 -o "$tmp/$file" "$url" \
        || ! curl -fsSL --max-time 30 -o "$tmp/SHA256SUMS.txt" "$sums"; then
        echo "$name: Download fehlgeschlagen"; failed+=("$name"); continue
    fi
    exp=$(grep -E " \*?$file\$" "$tmp/SHA256SUMS.txt" | cut -d' ' -f1)
    act=$(sha256sum "$tmp/$file" | cut -d' ' -f1)
    if [ -z "$exp" ] || [ "$exp" != "$act" ]; then
        echo "$name: PRUEFSUMME FALSCH (erwartet ${exp:-keine}, ist $act) - nicht installiert"
        failed+=("$name"); rm -f "$tmp/$file"; continue
    fi
    if flatpak install --user -y --noninteractive "$tmp/$file"; then
        updated+=("$name $new")
    else
        failed+=("$name")
    fi
    rm -f "$tmp/$file"
done

if [ ${#updated[@]} -gt 0 ]; then
    notify-send -a "Craft-Updates" -i system-software-update "Craft-Apps aktualisiert" "$(printf '%s\n' "${updated[@]}")" 2>/dev/null
fi
if [ ${#failed[@]} -gt 0 ]; then
    notify-send -a "Craft-Updates" -u critical "Craft-Update fehlgeschlagen" "${failed[*]} - siehe journalctl --user -u craft-flatpak-update" 2>/dev/null
    exit 1
fi
exit 0
