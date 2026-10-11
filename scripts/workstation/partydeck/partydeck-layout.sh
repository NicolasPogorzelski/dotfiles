#!/usr/bin/env bash
# Splitscreen-Anordnung fuer 2 Spieler umschalten (liest partydeck-tiler@nicolas live)
# Aufruf: partydeck-layout [oben-unten|links-rechts|toggle]   (ohne Argument = toggle)
set -euo pipefail

dir="$HOME/.config/partydeck-tiler"
file="$dir/layout"
settings="$HOME/.local/share/partydeck/settings.json"

current=$(cat "$file" 2>/dev/null || echo oben-unten)
case "${1:-toggle}" in
    oben-unten|links-rechts) new=$1 ;;
    toggle) [[ $current == links-rechts ]] && new=oben-unten || new=links-rechts ;;
    *) echo "Aufruf: partydeck-layout [oben-unten|links-rechts|toggle]" >&2; exit 1 ;;
esac

mkdir -p "$dir"
echo "$new" > "$file.tmp" && mv "$file.tmp" "$file"

# PartyDeck die passende Renderaufloesung mitteilen (wirkt ab dem naechsten Spielstart).
# Nur wenn PartyDeck nicht laeuft, sonst koennte es die Datei beim Speichern ueberschreiben.
hint=""
if pgrep -x partydeck >/dev/null; then
    hint=" - PartyDeck läuft: Bild passt erst nach Neustart des Spiels genau (sonst schwarze Ränder)"
elif [[ -f $settings ]]; then
    vertical=false; [[ $new == links-rechts ]] && vertical=true
    python3 - "$settings" "$vertical" <<'EOF'
import json, sys
path, vertical = sys.argv[1], sys.argv[2] == "true"
with open(path) as f:
    s = json.load(f)
s["vertical_two_player"] = vertical
with open(path, "w") as f:
    json.dump(s, f, indent=2)
EOF
fi

echo "Layout: $new$hint"
notify-send -a PartyDeck "Splitscreen: $new" "${hint# - }" 2>/dev/null || true
