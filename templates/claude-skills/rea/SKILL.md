---
name: rea
description: Startet Reverse Engineering mit REA (MCP-Server rea-agents) für diese Sitzung. Nur auf ausdrücklichen Aufruf mit /rea.
argument-hint: "[Ziel und Frage]"
disable-model-invocation: true
---

# REA starten

Aufruf: `/rea $ARGUMENTS`

REA ist ein Werkzeug, kein Lernstoff: Claude führt die Analyse selbst aus und liefert das Ergebnis.
Ohne `/rea` nutzt Claude die `mcp__rea__*`-Werkzeuge nicht, auch wenn sie in der Liste stehen.

## Ablauf

1. **Anweisungen laden:** `<home>/.local/share/rea/skill-6.7.0/SKILL.md` vollständig lesen, die
   Dateien unter `references/` erst, wenn die Aufgabe sie braucht. Fehlt die Datei, das sagen und
   auf den Abschnitt REA im dotfiles-README verweisen; nicht aus dem Gedächtnis arbeiten.
2. **Ablage:** Jede Aufgabe bekommt `<home>/rea/<projekt>/` (Kleinbuchstaben, Bindestriche). Das
   Ziel wird dorthin kopiert, alle Ausgaben landen dort, auch wenn die Sitzung in einem Repo läuft.
   Nie REA-Ausgaben, dekompilierten Code oder Ziele in ein Repository unter `~/git` schreiben.
3. **Statisch zuerst:** Analysen, die das Ziel starten (Prozessmitschnitt, adb, Browser), nur nach
   ausdrücklichem Ja für genau dieses Ziel. Sie laufen mit den Rechten des Nutzers.
4. **Ohne Argument:** nach Ziel und Frage fragen, dann beginnen.

## Am Ende einer Aufgabe

1. `ERGEBNIS.md` im Projektordner schreiben: Frage, Antwort, Belege, Grenzen. Offene Punkte und
   Zwischenstände gehören in `NOTIZEN.md`.
2. Größe von Ziel und Rohdaten nennen und fragen: **aufräumen** (Standard: alles außer
   `ERGEBNIS.md` und `NOTIZEN.md` löschen), **behalten** oder **archivieren** (Rohdaten als
   `.tar.zst`, Ziel löschen). Gelöscht wird erst nach dem Ja.
3. `ERGEBNIS.md` und `NOTIZEN.md` in `<home>/rea` committen. Das Repository hat kein Remote; die
   `.gitignore` lässt nur diese beiden Dateien je Projekt zu.

## Grenzen

- Eine aktive Rolle geht vor: unter `/rolle tutor` wird REA nicht ausgeführt, siehe `/rolle`.
- Die `ask`-Regel für `mcp__rea` bleibt: jeder Aufruf braucht die Bestätigung des Nutzers.
- `/rea` gilt bis zum Ende der Sitzung und wird nicht im Gedächtnis festgehalten.
