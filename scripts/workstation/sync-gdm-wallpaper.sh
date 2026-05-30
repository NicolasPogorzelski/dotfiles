#!/bin/bash
set -e

# CONFIGURE: home directory of the user running the Bing Wallpaper GNOME extension
WALLPAPER_USER_HOME="/home/YOUR_USERNAME"

WALLPAPER_DIR="${WALLPAPER_USER_HOME}/Pictures/BingWallpaper"
DEST="/usr/share/backgrounds/bing-current.jpg"
DCONF_FILE="/etc/dconf/db/gdm.d/01-background"

# find uses -maxdepth 1 to avoid recursing into subdirectories
LATEST=$(find "$WALLPAPER_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | sort | tail -n 1)

if [[ -z "$LATEST" ]]; then
    echo "No wallpaper found in $WALLPAPER_DIR" >&2
    exit 1
fi

echo "Current Bing wallpaper: $LATEST"

cp "$LATEST" "$DEST"
chmod 644 "$DEST"

mkdir -p "$(dirname "$DCONF_FILE")"

cat > "$DCONF_FILE" << EOF
[org/gnome/desktop/background]
picture-uri='file://${DEST}'
picture-uri-dark='file://${DEST}'
picture-options='zoom'
EOF

dconf update

echo "GDM wallpaper updated: $DEST"
