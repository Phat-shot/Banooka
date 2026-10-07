# Raum 1 – Stand und Wiedereinstieg

Stand: 7. Oktober 2026, Branch `claude/game-polish-sr1697`, HEAD = Commit
dieser Datei. Pausiert auf Wunsch des Nutzers.

## Erledigt (gepusht)

- **Gemeinsamer Baukasten G0–G5** (5b1b59d … fa041a0):
  - Wächter (Schaufenster-Teil `wache`, fester Zufall).
  - Wegdaten, Duckdurchlass, Prüfhaken.
  - Wegdecke, Kanten, Gelände, Bachband, Nebelstoff.
  - Waldrahmen, Baumfabrik, Rasenbau, 24 CC0-Modelle.
  - Stimmungsregler.
  - Werkstatt-Stationen 30–32.
  - Level 01 bleibt pixelgleich.
- **Level 05 „Hauerjagd“, Neubau nach `doku/level05-neubau.md`**:
  - Pakete P1a–P9, jedes einzeln unabhängig geprüft.
  - Nachbesserungen aus Jury-Runde 1 und 2 (62b55fb, 1838ed7, 5ad3504).
  - Jedes Paket hat `pruefe.sh` SAUBER bestanden, Level 01 bleibt pixelgleich.

## Offen bei Level 05

Jury-Runde 3 (Spiel 0 schwer / 2 mittel, Bild 1 schwer / 8 mittel), Liste
mit Belegen in `offen/l05_jury_runde3.md`. Der schwere Punkt: Das Bild
wiederholt überall denselben symmetrischen Graben mit flachem Rasen
darüber und hält neben Level 01 noch nicht stand.

Begonnene, **ungeprüfte** Arbeit liegt als Patch bereit:

- `offen/l05_runde3_unfertig.patch`
  - Dritte Nachbesserung, abgebrochen.
  - Betrifft Dauer-Slide-Deckel, Richtzeit, Findlinge, Lücken, Eiche, Torbuchen, Tobel und Gesamtbild.
  - Anwenden mit `git apply`, dann Proben, Wächter W und eine neue Jury-Runde.
- `offen/l05_doku_zwischenstand.patch`
  - Abgebrochener Schluss-Doku-Lauf.
  - Verlegt `doku/level05-neubau.md` nach `doku/raum1/` und aktualisiert CLAUDE.md, README und ARCHITEKTUR.
  - Erst nach der letzten Jury neu schreiben.

## Noch nicht begonnen

- **G6 Kameraplan** (Hochblick, Seitenansicht, Blenden): `baukasten.md` §1.6, §2.
- **Level 03, 04, 02** nach `entwurf_l03.md`, `entwurf_l04.md`, `entwurf_l02.md`, in dieser Reihenfolge.
- Nutzerentscheidungen: `entscheidungen.md`. Kamera- und Sprungmaße: `kamera.md`.

## Ablauf, der sich bewährt hat

Je Paket:
1. Bauen.
2. Unabhängige, kritische Prüfung.
3. Nachbessern, höchstens 5 Runden.

Je Level am Ende:
1. Spiel-Jury und Bild-Jury gegen Level 01.
2. Nachbessern, bis zu 4 Runden.
3. Schluss-Doku mit `pruefe.sh` SAUBER.

Wächter W bei jedem Commit:
- `parse.sh`
- `pruefe.sh`
- Schaufenster-Teil `wache` 6/6 pixelgleich
- Level-01-Logs gleich
