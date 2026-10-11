#!/usr/bin/env bash
# Startet PartyDeck und schreibt die Ausgabe nach ~/.local/share/partydeck/last-run.log
LOG=~/.local/share/partydeck/last-run.log
cd ~/Applications/partydeck || exit 1
exec ./partydeck "$@" > "$LOG" 2>&1
