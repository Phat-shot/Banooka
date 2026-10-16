# Level 05 – Jury-Runde 4 (Mängel)

Abgearbeitet im Commit „Level 05 R4-Mängel …“. Was geändert ist, was
bewusst nicht, und die Messungen: `doku/level05-neubau.md`, Abschnitt 13,
„R4“. Die Liste unten ist der Befund der Jury, gekürzt (Belege im Scratch
der Sitzung unter `raum1/abschluss/jury_r4/` und
`raum1/abschluss/jury_r4_spiel/`), dahinter der Stand nach R4.

## Spiel-Jury R4 (Stand HEAD 9983679)

- **mittel** – Gatter Ü und Joche D3/D4: Über dem Riegel ist die Mitte seit
  R3 offen (2,6 bzw. 4,6 m bis Kopfstange bzw. Trog), der Körper sperrt
  aber 0,95–4,4 m – eine unsichtbare Wand. Aus der Rückblickkamera liegt der
  Riegel unter der Figur wie eine Schwelle. D3 gesprungen statt Slide: 1×
  gestolpert, Mindestabstand 7,69 m. Vorschlag: ein Holm auf 1,9–2,3 m quer
  über die Gasse, den Körper nicht absenken.
  → **Holm** auf 2,06 m an Ü, D3, D4 (`L05Wegbauten`, HOLM_Y).
- **leicht** – Deckel nimmt dem einzelnen Slide den Vorsprung, solange der
  Keiler mehr als 2 m hinter der Staffel liegt (nach dem Wecken in B, nach
  jedem Respawn). → **Deckel nur in einer Slide-Kette** (`L05Jagd`,
  DECKEL_KETTE); dem Nutzer vorzulegen.
- **leicht** – Trittstein G3: Bahnen q +3,2 und +4,0 prallen bei 255,8
  frontal auf den Stein und werden gefangen. → nicht geändert, dem Nutzer
  vorzulegen.
- **leicht** – Früchte nach „Level geschafft“ gezählt (HUD 2 mehr als der
  Eintrag). → **behoben** (`Level05._nach_dem_ziel`, Reihe am Wehr verlegt).
- **leicht** – Kisten Gasse C auf q 2,0: Bahn q +1,5 prallt bei 166,6 auf
  und wird gefangen. → **q 2,2** wie die übrigen Gassen.
- **leicht** – Wehrbruch L6, Lesbarkeit (projiziertes Band schmaler als die
  Terrassenlücken, bleibt hell). → spielseitig reicht der Hinweis nach dem
  Sturz (Jury); nicht geändert.

## Bild-Jury R4 (Stand HEAD 9983679)

- **schwer** – Gesamtbild A–D: Neben L01 besteht L05 nicht. Strukturlose
  Blöcke oben 0,13–0,34 (Messgröße R3 erfüllt), aber derselbe symmetrische
  Graben in offener Parklandschaft, keine senkrechten Rahmenmassen, der
  Fernwald ohne Dunst; unten satter (HSV 179–217 gegen 157–186), heller
  (Luma 55,7–72,0 gegen 43,2–61,1) und wärmer (0,43–0,56 gegen 0,19–0,41)
  als L01. Vorschläge: (1) hohe Randstämme außen im Bild, (2) Kronenband
  dunkler, (3) Fernwald über den Nebel kühler und blasser, (4) Sättigung
  vorn −10 %. Die Waldkante (K3) dem Nutzer vorlegen.
  → (2), (3), (4) umgesetzt; (1) nicht (K3, Budget) – dem Nutzer vorzulegen.
- **mittel** – Wurzeltreppen S1–S3: weiter zwei gerade Leisten, Wurzeln als
  flache Flecken, an den Enden lachsfarbene Blöcke. → Erde an den Enden,
  Wurzeln dicker, unten verdeckt, über die Kante abtauchend.
- **mittel** – Lücken: Lippen schnurgerade, ohne überhängende Narbe; bei
  s 220 ein schwarzes Loch in der Sandsteinwand. → Narbenzungen, Grund und
  Lippenstufe dunkelbraun.
- **mittel** – Lösswände: Wurzelvorhänge als schwarze 1-px-Haarstriche
  (s 60: 455 Bildpunkte), Nahtrisse schwächer, Rillen wie Wischspur.
  → Vorhänge flach auf der Wand mit eigenem Atlas, warm-braun; Nahtrisse
  und Rillen nicht geändert.
- **mittel** – Schilf am Teich als braun-orange Klumpen („sitzende Tiere“).
  → Halme und Rohrkolben.
- **mittel** – Hauereiche fern: 4–5 glatte Ellipsoide je Hälfte („Pilzhüte“).
  → eine flache Schirmsilhouette je Hälfte mit Lappen und dunkler Unterseite.
- **mittel** – Tobel D: Farn als Konfetti, Sickerstreifen als glänzende
  Bänder (eines frei in der Luft), Puzzlelinien im Sandstein, Ufer bei 262
  als senkrechte Schnittfläche, keine Birken links. → Farnpolster auf den
  Simsen, Sickerspuren als dunkle Spur auf der Wand, Sandstein weich; Ufer
  und Birken nicht geändert.
- **leicht** – Torbuchen: Schirmkronen wie Pinien, fern blaugrau. → fern
  oliv; die Kuppelkrone nicht (neue Sichtliniensuche nötig).
- **leicht** – Fluderjoche: Trog oben nicht zu erkennen, naher Balken glänzt
  wie Plastikband. → Riegel oben matt (Borke); Trog nicht geändert.
- **leicht** – Startbild: Käfig aus Ober- und Fußriegel, U-Rinne, Lichtschacht
  waagerecht, Keiler als Fächer. → Lichtschacht steil; Rinne, Keiler, Käfig
  nicht (der Holm verstärkt den Käfig – dem Nutzer vorzulegen).
- **leicht** – Fernkulisse: stammlose Kronen, rosa Quader, Kugeln über dem
  Hang (ungeprüft, ob sie schweben). → nicht geändert.
- **leicht** – Licht und Farbe: heller und wärmer als L01. → siehe
  Gesamtbild (4).
- **leicht** – Wasser: Teich mit weißen Tupfern, Weißwasser als Rauschen.
  → Glitzern 0,1 statt 0,25, Weißwasser gröber (Null-Pfad im geteilten
  Wasserfall).
- **leicht** – Budget hängt von der Reihenfolge ab. → Ursache gefunden
  (Rand der Sichtweiten wirkt als Hysterese); dichte Reihen gemessen.
