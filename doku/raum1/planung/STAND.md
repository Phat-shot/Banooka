# Raum 1 – Stand und Wiedereinstieg

Stand: 16. Oktober 2026, Branch `claude/game-polish-sr1697`, HEAD = Commit
dieser Datei. Auftrag des Nutzers: „Fixe alles um Raum 1, aber L2-4 noch
nicht.“ Auf Wunsch des Nutzers pausiert (Kontingent).

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
- Runde 4 (Spiel und Bild gegen Level 01): `560a57d`; die
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

## Level 05: Jury-Runde 5 – offen, Nachbesserung begonnen

- Jury gegen `560a57d`, Mängel mit Belegen in `offen/l05_jury_runde5.md`:
  - Spiel: 1 mittel. Slide-Druck während eines laufenden Slides geht
    verloren, das trifft Dauer-Slider an Durchlass D2. Dazu 5 leicht.
  - Bild: 1 schwer. Gerader, symmetrischer Graben, seit R3 im Kern gleich;
    nur mit Umbau des Verlaufs bzw. Waldkante lösbar, siehe K3 oben.
    Dazu 6 mittel, u. a. Sickerspuren als schwarze Bänder, Primitiv-Reserve
    in der Doku falsch, Eiche fern, Lücken, Joche, Wurzeltreppen.
- Begonnene, **ungeprüfte** Nachbesserung: `offen/l05_runde5_unfertig.patch`
  (gegen `560a57d`, `git apply`).
  - Enthält den Slide-Puffer an D2. Der berührt `scenes/player/player.gd`,
    dort Null-Pfad prüfen.
  - Enthält Teile der Bild-Mängel. Berührt auch das geteilte
    `scenes/props/kronenwolke.gd`.
- Danach: Proben, Wächter W, Commit. Eine Jury-Runde 6 ist nicht nötig, der
  Rest geht ehrlich in die Schluss-Doku.

## Raum-1-Audit: 19 bestätigte Funde, noch nicht behoben

Drei Audits (Level 01, Portalraum/Spielfluss, Baukasten) gegen `b67450e`,
jeder Fund unabhängig reproduziert: `offen/audit_raum1_funde.md`.
Wichtigste (mittel):
- **H1:** Wurzelbogen im Hub fängt die Figur zwischen Tor 03 und 04.
- **H2/H6:** Freischalt-Anzeige und Vorladen zählen linear, die
  Freischaltung selbst raumweise.
- **H3:** „Neu starten“ in der Game-Over-Pause, danach wirft der alte Timer
  in den Portalraum.
- **H4:** Fruchtsummen nach Abzug fürs Extraleben.
- **H5 = L01-A1:** Level 01 ohne `zielzeit()`, Platin zu leicht.
- **B1:** Bauspeicher-Schlüssel L05; **B2:** `pruefe.sh`-Lücken;
  **B4:** Doku-Widerspruch.

## Nächste Schritte (in dieser Reihenfolge)

1. Nutzerentscheidungen oben einholen (K3/Waldkante, Richtzeit, Deckel, G3,
   Holm).
2. `offen/l05_runde5_unfertig.patch` anwenden, fertig machen, prüfen,
   committen.
3. Audit-Funde beheben, ohne L05-Dateien und Doku. B1/H11/B3/B4 macht die
   L05-Doku. Das geht parallel zu 2 im eigenen Worktree; danach eine
   unabhängige Prüfung.
4. Schluss-Doku L05: `offen/l05_doku_zwischenstand.patch` nur als Vorlage,
   verlegt `doku/level05-neubau.md` nach `doku/raum1/`, CLAUDE.md, README,
   ARCHITEKTUR.
5. Schluss: `pruefe.sh` SAUBER, Wächter W, STAND.md, Bildbogen, APK.

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
2. Nachbessern, bis zu 4 Runden; hält ein schwerer Mangel zwei Runden
   lang, liegt er im Entwurf: dann Nutzer fragen statt weiter nachbessern.
3. Schluss-Doku mit `pruefe.sh` SAUBER.

Wächter W bei jedem Commit:
- `parse.sh`
- `pruefe.sh`
- Schaufenster-Teil `wache` 6/6 pixelgleich
- Level-01-Logs gleich
