#!/usr/bin/env bash
# Restore the PartyDeck splitscreen setup on a fresh Bazzite install (the reverse of
# sync-from-live.sh): PartyDeck itself from its latest GitHub release if it is missing,
# then starter, layout switch, menu entry, settings, game handlers and the partydeck-tiler
# GNOME extension from files.list. Runs again safely; an installed PartyDeck is kept.
# Live files that would change are kept as <file>.bak-<date>.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%F)
home_real=$(readlink -f "$HOME")
app="$HOME/Applications/partydeck"
uuid=partydeck-tiler@nicolas

if [ ! -x "$app/partydeck" ]; then
    # The SteamOS tarball, not the AppImage: the AppImage lacked res/goldberg (2026-10-03).
    # The project publishes no checksums; the download is only as good as GitHub's TLS.
    url=$(curl -fsSL https://api.github.com/repos/partydeck/partydeck/releases/latest |
        jq -r '.assets[] | select(.name | test("SteamOS-x86_64\\.tar\\.gz$")) | .browser_download_url')
    [ -n "$url" ] || { echo "no SteamOS tarball in the latest PartyDeck release" >&2; exit 1; }
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    echo "downloading ${url##*/}"
    curl -fsSL --max-time 600 -o "$tmp/pd.tar.gz" "$url"
    mkdir "$tmp/x" && tar -xzf "$tmp/pd.tar.gz" -C "$tmp/x"
    bin=$(find "$tmp/x" -maxdepth 3 -type f -name partydeck -perm -u+x | head -1)
    [ -n "$bin" ] || { echo "no partydeck binary in ${url##*/}" >&2; exit 1; }
    mkdir -p "$(dirname "$app")"
    cp -a "$(dirname "$bin")" "$app"
    echo "installed: $app"
fi

while IFS='|' read -r rel live; do
    case "$rel" in ''|'#'*) continue ;; esac
    src="$here/$rel" dst="$HOME/$live" new=$(mktemp)
    if grep -qI . "$src"; then sed "s|@HOME@|$home_real|g" "$src" > "$new"; else cp "$src" "$new"; fi
    if [ -f "$dst" ]; then
        cmp -s "$new" "$dst" && { rm -f "$new"; continue; }
        cp -p "$dst" "$dst.bak-$stamp"
    fi
    install -D -m "$(stat -c %a "$src")" "$new" "$dst"
    rm -f "$new"
    echo "restored: $dst"
done < "$here/files.list"

enabled=$(gsettings get org.gnome.shell enabled-extensions)
case "$enabled" in
    *"'$uuid'"*) ;;
    '@as []'|'[]') gsettings set org.gnome.shell enabled-extensions "['$uuid']" ;;
    *) gsettings set org.gnome.shell enabled-extensions "${enabled%]}, '$uuid']" ;;
esac

# The Proton build settings.json names (e.g. GE-Proton11-7-x86_64), from its GitHub
# release, checked against the published sha512sum before it is unpacked.
proton=$(jq -r .proton_version "$HOME/.local/share/partydeck/settings.json")
name=${proton##*/}
if [ ! -d "$proton" ] && [[ $name =~ ^GE-Proton[0-9-]+-x86_64$ ]]; then
    tag=${name%-x86_64}
    base="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$tag/$name"
    ptmp=$(mktemp -d)
    echo "downloading $name.tar.gz (about 550 MB)"
    if curl -fsSL --max-time 1800 -o "$ptmp/$name.tar.gz" "$base.tar.gz" &&
        curl -fsSL -o "$ptmp/$name.sha512sum" "$base.sha512sum" &&
        [ "$(cut -d' ' -f1 "$ptmp/$name.sha512sum")" = "$(sha512sum "$ptmp/$name.tar.gz" | cut -d' ' -f1)" ]; then
        mkdir -p "${proton%/*}"
        tar -xzf "$ptmp/$name.tar.gz" -C "${proton%/*}"
        echo "installed: $proton"
    else
        echo "WARNING: $name download or checksum failed - nothing installed" >&2
    fi
    rm -rf "$ptmp"
fi
[ -d "$proton" ] || echo "WARNING: $proton is missing - install $name (ProtonPlus) or pick another Proton in PartyDeck" >&2

cat <<EOF
Done. Still to do:
 - log out and in once: GNOME on Wayland loads the tiler extension only at login
 - Steam: install the games the handlers point to (Secrets of Grindea, appid 269770)
 - PartyDeck creates its profiles and prefixes on first start; saves are not in this repo
 - In PartyDeck's settings keep the SDL backend for gamescope OFF (its GUI turns it back on)
EOF
