---
name: rolle
description: Startet eine oder mehrere Rollen (tutor, reviewer, devsecops, pruefer), aus denen Claude für den Rest der Sitzung ausschließlich handelt. Nur auf ausdrücklichen Aufruf mit /rolle.
argument-hint: "[tutor|reviewer|devsecops|pruefer ...] | aus"
disable-model-invocation: true
---

# Rolle starten

Aufruf: `/rolle $ARGUMENTS`

Die Rollen liegen als je eine Datei unter `~/.claude/skills/rolle/rollen/<name>.md`.

## Ablauf

1. **Ohne Argument:** Alle Dateien in `rollen/` auflisten, je Rolle eine Zeile (Name und erster
   Satz). Keine Rolle starten, auf die Wahl warten.
2. **`aus`:** Die aktive Rolle endet. Ab da gilt wieder das normale Verhalten. Das in einem Satz
   bestätigen.
3. **Ein oder mehrere Namen:** Jede genannte Datei vollständig lesen. Ist ein Name unbekannt,
   die vorhandenen Rollen nennen und nichts starten. Danach in einer kurzen Zeile bestätigen,
   welche Rolle aktiv ist und was sie ausschließt. Dann auf das erste Anliegen warten.

## Was eine aktive Rolle bedeutet

- Bis zum Ende der Sitzung, bis `/rolle aus` oder bis zu einem neuen `/rolle`-Aufruf handelt
  Claude **nur** aus der Rolle heraus. Ein Anliegen außerhalb der Rolle wird benannt und nicht
  nebenbei erledigt. Dann fragen, ob die Rolle gewechselt werden soll.
- Was die Rolle zum Verhalten regelt, geht den allgemeinen Vorgaben aus CLAUDE.md vor
  (Lernmodus, Prüfung aus mehreren Blickwinkeln, Erklärpflichten).
- Was **nicht** außer Kraft gesetzt wird: Veröffentlichen bleibt beim Nutzer (kein Push, kein
  PR), die Commit-Regeln, der Schreibstil der Repositories und die Hooks.
- **Mehrere Rollen:** Beide gelten gleichzeitig. Widersprechen sie sich, gilt die strengere
  Einschränkung, z. B. schlägt "führt nichts aus" (tutor) "misst selbst" (devsecops).
- Die Rolle wird nicht in Dateien oder im Gedächtnis festgehalten. Sie gilt nur für diese Sitzung.
