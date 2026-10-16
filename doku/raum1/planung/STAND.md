# Raum 1 – Stand und Wiedereinstieg

Stand: 16. Oktober 2026, Branch `claude/game-polish-sr1697`, HEAD = Commit
dieser Datei (lokal, nicht gepusht). Auftrag des Nutzers: „Fixe alles um
Raum 1, aber L2-4 noch nicht.“

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

## Level 05: Jury-Runden 3 und 4 abgearbeitet

- Runde 3: Spiel-Teil `9f95ee7`, Bild-Teil `9983679`; Mängel mit Belegen in
  `offen/l05_jury_runde3.md`.
- Runde 4 (Spiel und Bild gegen Level 01): im Commit dieser Datei; die
  Übersicht mit den Messungen steht in `doku/level05-neubau.md`,
  Abschnitt 13, „R4“, die Mängel gekürzt in `offen/l05_jury_runde4.md`.
  Behoben bzw. umgesetzt: Holm über Gatter und Jochen, Deckel nur in einer
  Slide-Kette, Früchte nach dem Ziel, Kisten der Gasse C, Kronenband,
  Nebel B/C, Sättigung, Wurzeltreppen (lachsfarbene Enden), Lücken
  (Zungen, Loch bei s 220), Wurzelvorhänge, Schilf, Eiche fern, Tobel D
  (Farn, Sickerspuren, Sandstein), Weißwasser (Null-Pfad im geteilten
  Wasserfall), Ursache des Reihenfolgeeffekts im Budget.
- Nicht geändert (Gründe in R4): Randstämme (K3, Budget), Trittstein G3,
  Torbuchen als Kuppel, Trog der Joche, Rinne und Keiler im Startbild,
  Fernkulisse, Ufer bei 262, Birken in D, Rillen und Nahtrisse der
  Lösswände.
- Dem Nutzer vorzulegen: Richtzeit 32 s (Saphir/Gold/Platin), Deckel gegen
  den Dauer-Slide (seit R4 nur in der Slide-Kette), Waldkante auf q 10–20
  (K3 lässt in A und B keine hohen Bäume an die Kronen; die Bild-Jury
  macht „besteht“ davon abhängig), Trittstein G3, Holm gegen „Käfig“ im
  Startbild, Spielfigur.

Nächster Schritt: Die vier Nachbesserungsrunden sind durch. Die
Entscheidungen oben beim Nutzer einholen, dann die Schluss-Doku –
`offen/l05_doku_zwischenstand.patch` neu schreiben (verlegt
`doku/level05-neubau.md` nach `doku/raum1/` und aktualisiert CLAUDE.md,
README und ARCHITEKTUR).

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
