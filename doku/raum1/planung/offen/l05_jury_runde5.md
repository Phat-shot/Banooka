# Level 05 – Jury-Runde 5 (gegen 560a57d)

Unbearbeitet; `l05_runde5_unfertig.patch` enthält den begonnenen, ungeprüften Teil der Nachbesserung.

## Spiel-Jury (ok = False)

### mittel: Durchlass D2 (Stirn 104,0) nach Hürde H2, beim Slide als Spurt; Slide-Annahme in scenes/player/player.gd:217 (Slide startet nur bei sliding <= 0) zusammen mit der Stolperzone von L05 (Level05._durchlass_stolpern)

**Befund:** Tippt man Slide, während noch ein Slide läuft, geht der Tastendruck verloren; es gibt keinen Eingabepuffer. Wer nach der Landung von H2 (s 95,5–96,6) als Spurt slidet, ist mit diesem Slide erst kurz vor D2 fertig, nämlich zwischen 101,0 und 102,7. Der Tipp für D2 fällt dann in den noch laufenden Slide, die Figur richtet sich auf und stolpert bei 103,5–103,6. Gemessen: (a) Fall „d2“ ab CP1, Spurt-Slide nach der Landung, D2-Tipp bei Stirn −3,5 bzw. −3,0: beide Male gestolpert und gefangen (Mindestabstand 2,10 m, 36 Bilder Hänger). Tipps bei −2,5 bis −0,7 gehen sauber durch (Mindestabstand 9,19 m). (b) Dauer-Slide (zeit_spam_eine): Der Slide ab der Landung endet bei 102,69, der Tipp bei 102,0 geht verloren, gestolpert bei 103,5; 1,07 s später gefangen (2,11 m, 39 Bilder Hänger). (c) Kette mit Dauer-Slide: Nach dem Respawn an CP1 viermal hintereinander dieselbe Falle (TOD 2–5 jeweils bei 103,62); nach dem fünften Tod Game Over. Dasselbe Bild zeigt schon das R4-Log jury_r4_spiel/logs/jury_zeit_spam_eine.log (rc=1); in R4 wurde es nicht berichtet. Gegenproben: Wer sofort nachtippt, sobald der Slide endet, stolpert nicht (102,40 bzw. 102,51). Wer 0,25 s nach dem Stolpern nachtippt, überlebt mit 4,82 m. Wer gar nicht nachtippt, ist tot. Das Level lehrt den Slide als Spurt (Lehrfolge Nr. 4) und rechnet mit dem Deckel ausdrücklich mit Dauer-Slidern. Gerade diese Spieler erleben an D2 „ich habe gedrückt, und nichts passiert“.

**Vorschlag:** Ohne Physikänderung und nur im Level (Null-Pfad): Den Slide, der in den letzten ~0,25 s eines noch laufenden Slides gedrückt wurde, in L05 merken und beim Slide-Ende auslösen. Alternativ in Level05._durchlass_stolpern einen solchen gemerkten Druck als Slide werten statt als Stolpern. Ein allgemeiner Eingabepuffer in player.gd nur als Opt-in mit Schalter. Danach die Fälle d2, zeit_spam_eine und Kette mit Dauer-Slide erneut laufen lassen.

### leicht: BEGEHBARES „G3 Trittstein“ (s 256,3–257,7, q 2,7–4,1); offen aus R3 und R4

**Befund:** Unverändert. Bahn q +3,2 vom Start prallt bei 255,8 frontal auf den Stein, 55 Bilder Hänger, gefangen (Mindestabstand 2,03 m). Bahn q +4,0 ab CP1: 47 Bilder Hänger, gefangen bei 255,8 (2,11 m). Bahnen q −4,0 / −2,6 / −1,5 / +1,5 sowie beide Randspuren kommen ohne Hänger ins Ziel.

**Vorschlag:** Liegt beim Nutzer (Liste „Dem Nutzer vorzulegen“). Wenn gebaut wird: Vorderseite anschrägen oder eine Fruchtlinie bzw. helle Lippe links am Stein vorbei.

### leicht: Kistengassen der Hauptlinie (14 Gassen, Kisten auf q 2,2), besonders Gasse 36 direkt nach dem Wecken

**Befund:** Auf den Spuren von etwa q 1,7 bis 2,9 sind die Kisten eine Wand. Bahn q +2,6 ab CP1 läuft bei 35,1 frontal auf die erste Kiste der Gasse 36: 80 Bilder ohne Fortkommen, dann gefangen (2,06 m; der Keiler kommt aus 15 m Weckabstand mit 10,5 m/s heran). Bahnen q ±1,5 und −2,6 sowie die Randspuren laufen durch; seit R4 ist die Gasse C auf q 2,2 und q 1,5 frei. Ein Mensch, der dreht oder ausweicht, verliert dort nichts; wer stur gegen die Kiste drückt, ist nach gut 1,3 s tot.

**Vorschlag:** Hinnehmen (Kisten sind Hindernisse wie in Level 01) oder nur die Gasse 36 direkt nach dem Wecken eine Spur weiter nach außen (q ≥ 2,8) legen. Dem Nutzer zur Kenntnis.

### leicht: Jagddruck im Tobel D (L05Jagd.HOECHST_STAFFEL 172–234: 14 m; ab 240: 10 m); offen aus R3, leicht

**Befund:** Teilweise behoben. Der Ideallauf hat in D jetzt im Mittel 11,56 m (R3: 12,74). D bleibt trotzdem der Abschnitt mit dem geringsten Druck: B 10,28 / C 8,04 / D 11,56 / E 7,66 m; der Keiler ist in D 52 px hoch (min 44), in C 59 px. Im Dauer-Slide sind es 13,71 m im Mittel (max 16,00), 47 px (min 43). In der Kette mit Dauer-Slide 14,07 m. Ein freier Slide bringt bei 186 nur +0,57 bzw. +0,67 m. Begründung „Kette verzeiht zwei Fehler“: Stolpern an D3 und D4 kostet bis auf 4,46 m.

**Vorschlag:** Mit der Staffel dem Nutzer vorlegen (bewusste Entscheidung, kein Codefehler).

### leicht: Zeitmodus, Level05.ZIELZEIT 32,0 (Saphir 32,0 / Gold 27,2 / Platin 23,04)

**Befund:** Die Stufen entsprechen dem Kopf. Ideallinie ohne Kiste 35,23 s: keine Stufe. Dauer-Slide ohne Kiste 29,55 s: Saphir. Dauer-Slide mit Gasse 36 (1 s + 3 s) 25,53 bzw. 25,73 s: Gold. Alle Gassen mit Drehschlag 7,57 s: Platin. Dauer-Slide mit Gassen 8,38 s: Platin. Ein Tod beendet den Lauf („Zeitlauf beendet“, kein Eintrag). Die 15 Zeitkisten halten die Uhr zusammen 30 s an, das sind 94 % der Richtzeit. Wer ohne Spurt die Gassen mitnimmt, liegt bei 7,57 s und damit dreifach unter der Platin-Grenze. Platin trennt also kaum.

**Vorschlag:** Mit diesen Zahlen dem Nutzer vorlegen (Richtzeit steht ohnehin auf seiner Liste).

### leicht: Wehrbruch L6 (284–289), Lesbarkeit aus der Rückblickkamera; offen aus R3, spielseitig in R4 als ausreichend bewertet

**Befund:** Teilweise behoben. Der Hinweis „Über das Wehr: in der Luft noch einmal springen!“ kommt genau einmal nach dem ersten Sturz (Kette, Fehler, Kette mit Dauer-Slide). Fenster für den Doppelsprung 281,75–284,25 (2,50 m), der Einzelsprung trägt nirgends. Das projizierte Band ist unverändert: 368 / 121 / 56 / 45 px bei 12 / 8 / 4 / 2 m Anlauf, schmaler als bei L2/L3 (292 / 129 / 84 / 71). Auf den Fotos 284 und handy 282 erscheint der Bruch als dünner Streifen von etwa 30–45 px direkt vor der Figur. Der Wehrbogen steht seitlich bildlinks, liest sich aber als steigende Reihe, nicht als Bogen. Die Früchte nach dem Wehr liegen bildrechts und verdecken die Figur nicht mehr.

**Vorschlag:** Kein neuer Spielmangel. Die Bildfrage hell/schmal mit der Bild-Jury abstimmen.

### Messungen

Stand HEAD 560a57d, sauber und unverändert; geändert nur in der Scratch-Kopie (git archive). Proben mit 60 Hz, je Lauf ein frischer Benutzerordner. Alles unter /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/jury_r5_spiel/. Werkzeuge: Juryprobe aus jagdprobe.gd + jury_zusatz_r4.gd (gleich wie in R4), dazu in der Kopie die R5-Fälle d2, ueber_holm, Kette mit Dauer-Slide, SPAM_NACH=2.

STANDARDPROBEN
- LevelCheck: === 0 Fehler, 0 Warnungen ===
- Sprungprobe: 21 Fälle, 0 Fehler. Alle Pflichtsprünge tragen.
  - Lücken: L1 2,00 m, L2/L3 2,00, L4 1,50, L5 1,75.
  - Wehr Doppelsprung 2,50 m; der Einzelsprung trägt nirgends.
  - Durchlässe: Ü 3,25, D1/D2 3,00, D3/D4 3,25.
  - Hürden H1/H2 1,75.
  - Kür: G3 Trittstein 1,00, Sims 0,50, Wehr Slide-Sprung 0,75.
- Jagdprobe: 24 Fälle, 0 Fehler, bis auf die Bildzahl zeilengleich mit R4.
  - Ideal: Mindestabstand 6,94 m, 30,95 s ab dem Wecken.
  - Dauer-Slide je Strecke: 10,50 / 9,00 / 15,16 / 8,19 m (Grenzen 12 / 10,5 / 16,5 / 11).

SPIELTEST über den Portalraum (Bot, xvfb)
- Geschafft, 0 Tode, Uhr 36,5 s, 83 Früchte, freigeschaltet bis 6.
- Einmal gestolpert an H2, wie in R4 (Eigenheit des Bots).
- HUD während des Laufs: 71 Früchte, 0/49 Kisten.

ZÄHLUNG HUD = EINTRAG (R4-Mangel behoben)
- stat 83/83, alles 26/26 (49/49 Kisten, „Alle Kisten! Edelstein erhalten“), g3spaet 25/25, zeit_kisten 83/83 (R4: 85/83), zeit_spam_kisten 87/87, bahn2 16/16.
- Portal 5, vier Zustände:
  - Kisten + ohne Tod: Steine 66d9ff und ff576b.
  - Saphir 29,55: Steine ff576b und 599efa.
  - Gold 25,53: Stein ffc742.
  - Platin 7,57: Steine 66d9ff und dbf0ff.
  - Jeweils Schild GESCHAFFT, Bestzeit mit Komma.
  - Die SCRIPT ERRORs (level06.gd) stammen nur vom Beenden der Probe mitten im Vorladen; mit 900 Bildern Wartezeit 0 Fehler.

TOD UND RESPAWN AN JEDEM CHECKPOINT
- Kette Sturz und Kette Fang: 5/5 Respawns an 31 / 122 / 178 / 204 / 268, jeweils danach ins Ziel.
  - Keiler 12,16–12,20 m hinter der Figur, wartet.
  - Durchlässe hinter dem Checkpoint heil; Kisten nach dem Checkpoint zurückgesetzt (kisten_tod 2/49 → 5/49).
  - Wehrhinweis einmal; nach 5 Toden Leben 0 und weiterspielbar (Game Over erst bei <0, geteilte Regel).

DAUER-SLIDE (R3 mittel, BEHOBEN)
- Abstand im Mittel B / C / D / E:
  - spam: 11,58 / 8,86 / 13,71 / 7,81 m (R3: 15,1 / 14,5 / 16,0 / 11,4; Ideal: 10,28 / 8,04 / 11,56 / 7,66).
  - Kette mit Dauer-Slide, nachgetippt: 11,76 / 9,90 / 14,07 / 9,55.
- Keiler zu 100 % im Bild, 47–54 px hoch.

DECKEL NUR IN DER KETTE (R4 leicht, BEHOBEN)
- Gewinn eines freien Slides:
  - Slide bei 48: +1,94 m (s 56), +0,81 m (s 63).
  - Slide bei 131: +1,76 m (s 135), +0,33 m (s 140).
  - Slide bei 274: +0,76 m (s 276), +2,23 m (s 279).
  - Bei 186 nur +0,57 / +0,67 m.
- Ein freier Sprung kostet 0,4–1,3 m.

HOLM (R4 mittel, BEHOBEN)
- Fotos 012 / 207 / 212 / 219: Ein zweites Holz liegt quer über die ganze Breite, der Spalt zwischen Riegel und Holm ist sichtbar kleiner als die Figur; die Mitte des Gatters ist ohne Stangen.
- Über den Holm springen (Doppelsprung bei −3 / −2, Slide-Sprung), danach Slide 0,25 s nach dem Stolpern: immer 1× gestolpert, überlebt.
  - Mindestabstand D3 7,07–7,94 m, D4 7,83–8,60 m, D1 3,35–4,07 m.
- Fehlerfälle wie in R4: D3 gesprungen 7,69 m, D1 4,03 m; H1/H2 zu spät 8,65 / 5,96 m.

SAMMELN / G3
- G3-Sims (R3, BEHOBEN): Drehschlag erst bei 258,9 → 49/49, kein Hänger am Sims.

STECKENBLEIBEN
- Randspuren rechts und links: ins Ziel ohne Hänger.
- Bahnen ab CP1: q ±1,5, −2,6, −4,0 ohne Hänger.
- Hänger mit Folgen:
  - q +2,6: an der Kiste 36,0 (80 Bilder).
  - q +3,2 / +4,0: am Trittstein 255,8 (55 / 47 Bilder).
  - D2-Falle (36–39 Bilder).
- Bahn q −3,2 vom Start bleibt im Suhlgraben (23,5–28,1) stehen, weil der Bot nicht springt; vor dem Wecken, kein Softlock.

KAMERA
- Gefahren sind 13,5–16,5 m vorher im Bild (1,59–1,94 s bei 8,5 m/s, im Slide etwa 1,0 s). Lückenbänder gleich wie in R4.

ZEITMODUS
- 15 Zeitkisten, zusammen 30 s.
- Ideal 35,23 s: keine Stufe. Dauer-Slide 29,55: Saphir. Mit Gasse 36 25,53 bzw. 25,73: Gold. Gassen 7,57: Platin.
- Ein Tod beendet den Lauf.

KOSTEN (Fotos)
- Rechner höchstens 292 Draws, 707 749 Primitive (s 219).
- Handy höchstens 292 Draws, 527k Primitive.

UNGEPRÜFT
- Echte GPU, Gerät, Web-Export, Lauf von Hand.
- Ob ein Mensch nach einem verschluckten D2-Tipp nachtippt (angenommen 0,25 s Reaktion).
- Spieltest-Screenshots ohne 3D (wie in R4), daher nur HUD.

## Bild-Jury (ok = False)

### schwer: Gesamtbild A–D, s 8–140 und 186–262 (desktop/verfolger_03_060.png, 06_130, 07_140, zusatz/verfolger_01_120.png; Bogen vergleich_l01_r5.png, vergleich_r3_r4_r5.png)

**Befund:** Besteht neben L01 nicht. Das Bild ist seit R3 im Kern unverändert: ein gerader, symmetrischer Graben mit zwei senkrechten Wänden, links und rechts darüber eine flache Rasenebene mit verstreuten Büschen, dahinter stammlose Fernkronen und viel Himmel. Senkrechte Rahmenmassen (Stämme, Kronendach) fehlen; L01 rahmt jedes Bild damit. Die R4-Maßnahmen (dunkleres Kronenband, Nebel B/C, Sättigung 0,85) zeigen sich in den Zahlen, im Lesen des Bilds aber kaum: R3, R4 und R5 sind als Vorschau fast gleich. Messung R5 gegen L01: Himmelsanteil in B (s 52–90) 0,17–0,20, L01 0,08–0,11; Luma 54,7–73,5 gegen 43,3–61,1; warm 0,41–0,50 gegen 0,18–0,42; kühl 0,13–0,25 gegen 0,20–0,35; Sättigung unten 166–201 gegen 157–186 (R3 noch 193–227, das ist besser); flach oben 0,14–0,38 gegen 0,24–0,32. s 8 ist heller als in R3 (Luma 66,4 → 73,5). Es liest sich weiter als Entwässerungsgraben im Park, nicht als Hohlweg im Hangwald.

**Vorschlag:** Ohne die Waldkante (K3) ist das nicht zu lösen: Randstämme außen ins Bild, q 10–20. Das muss der Nutzer entscheiden. Vorher Budget freimachen (siehe Mangel Budget: die Reserve ist kleiner als dokumentiert), etwa beim Fernwald hinter der Kuppe, bei unsichtbaren Feldreihen oder beim Rasen außerhalb des Bildstumpfs. Den Himmel in B mit Kronen von oben anschneiden statt mit mehr Wolken.

### mittel: NEU (R4, 560a57d): Sickerspuren an der Südwand im Tobel D, s 186–262 und Seitenansicht 286 (holm/verfolger_01_203.png, zoom/z240_suedwand.png, zoom/z220_186_suedwand_r4_r5.png, zoom/z286s_strich_r3_r4_r5.png)

**Befund:** Die „nasse Spur“ aus R4 (wasser.gd `_sicker_stoff`: unbeleuchtet, BLEND_MODE_MUL, Vertexfarbe 0,5/0,55/0,52) wird als rein schwarzer, hart begrenzter Strich gezeichnet: rgb 1–2, 6–12 px breit, bis 90 px lang, diagonal über die Wand. Er wirkt wie ein Riss oder ein schwarzer Schlauch. Erwartet wäre eine Abdunklung auf rund die Hälfte. Messung, Strichpunkte (Summe < 9, 4 px daneben > 40): s 196 R4 407 → R5 1314; s 240 R3 223 / R4 856 / R5 2235. Seite 286, Feld x 100–170 / y 80–200, fast schwarz: R3 0 / R4 0 / R5 767. Neu fast schwarze Pixel in der rechten Bildhälfte gegenüber R4: s 186 4371, s 208 5510, s 220 8149, s 240 5145. Die Bilder des Nachbesserers (l05_r4/bilder/e2_seite, e2_holm/203) sind mit meinen byte-gleich und zeigen den Strich; in Doku R4 steht er nicht.

**Vorschlag:** Ursache klären; ungeklärt ist sie, und ob eine echte GPU oder der Web-Export dasselbe zeigt, ist ungeprüft. Bis dahin die Spur abschalten oder ohne Mischmodus bauen: dunkle Farbe mit Alpha, oder in die Gelände-Vertexfarbe der Südwand backen. Abnahme: Luma der Spur ≥ 0,5 × Wand daneben, kein Pixel mit Summe < 12.

### mittel: Budget, Primitive (scan_a/scan_b alle 4 m; dicht_e 262–290 und dicht_c 150–172 alle 2 m; kalt_276, kalt_164)

**Befund:** Die Grenze ≤ 750k wird überall eingehalten. Die in Doku R4 genannte Reserve (16k bei s 186) stimmt aber nicht. Dichte Reihe ab 262 alle 2 m: s 274 743 526, s 276 747 074 → Reserve 2 926 (0,39 %). Raster 4→300 alle 8 m: s 276 746 773. s 164 736 303 (dicht ab 150: 733 885) liegt in keiner R4-Reihe. Kalt angefahren nur 695 134 (276) bzw. 687 404 (164). Die R4-Reihe dicht3 begann kalt bei 276 (695k) und unterschätzt die Spitze um gut 50k (Hysterese der Sichtweiten-Ränder, R4 selbst beschrieben). Draw-Calls höchstens 313 (s 280, ≤ 500), Handy 294 (≤ 450), VRAM 107,6 / 83,0 MB. Die Zahl „16k Reserve“ ist Grundlage der Nutzerentscheidung über K3 und die Waldkante.

**Vorschlag:** Reserve in Doku und Vorlage auf rund 3k bei s 276 korrigieren. Messreihen immer mit ≥ 10 m Anlauf vor der ersten Stelle beginnen und 160–170 sowie 270–280 dazunehmen. Vor jedem Ausbau (Waldkante) in E (s 270–280) mindestens 30–50k freimachen. Ungeprüft: Rückwärtslaufen und Respawn an CP5 als weitere Hysteresepfade.

### mittel: Hauereiche fern und Wechsel nah→fern (desktop/verfolger_04_072.png, zoom/p072_eiche_fern.png, zoom/eiche_wechsel_56_76.png, handy/verfolger_00_060.png)

**Befund:** Die Nahfassung ist behoben: Der helle Reißverschluss-Spalt aus R3 ist weg. Die Fernfassung aus R4 aber ist je Hälfte ein glatter, flacher Hut mit gezacktem orangem Rand und dunkler, waagerecht abgeschnittener Unterseite auf glattem, dunklem Stiel: zwei Pilze oder Muffins auf einem Y, pilzartiger als in R3/R4. Im Raster wechselt die Eiche zwischen s 68 und s 72 von Laubballen mit Borkenstamm zur Pilzform mit dunklem glattem Stamm, mitten in B. Das Wahrzeichen springt also sichtbar. Auf dem Handy steht schon bei s 60 die Pilzform groß im Bild.

**Vorschlag:** Fernfassung aus dem Umriss der Nahkrone ableiten (Impostor aus der Nahkrone, unregelmäßiger Rand, Lichtlöcher, keine Kreisscheibe). Gleicher Stammstoff nah und fern. Übergang überblenden oder in den Nebel legen. Abnahme mit Bildern alle 2 m um die Sichtweite.

### mittel: Lücken L1–L5 (desktop/verfolger_06_130.png, 08_186, 10_220; zoom/p130_luecke.png)

**Befund:** Teilweise behoben: Die Innenwand ist dunkelbraun mit Verlauf, dazu hängende Wurzeln und Narbenzungen; das schwarze Loch bei 220 ist weg. Die Lücke bleibt aber ein exakt rechteckiger Kasten: flache, senkrechte Stirnwände, gerade Lippe, Lippensteine als flache graue Scheiben, die Frucht schwebt im Dunkel. Neben der Lücke in L01 (Erdflanken, Tiefe) weiter schwach.

**Vorschlag:** Stirnwände schräg und gerundet in die Böschung führen, Lippe mit Ausbrüchen ≥ 0,3 m statt Zungen ≤ 0,22 m, Steine als Brocken mit Höhe. Sichtbarkeit aus 14 m mit Bild prüfen.

### mittel: Joche D3/D4 und Gatter Ü mit Holm (desktop/verfolger_09_208.png, 10_220, holm/verfolger_01_203.png, handy/verfolger_01_218.png, holm/verfolger_00_012.png)

**Befund:** Mit dem Holm liest sich jedes Joch als Absperrung oder Sägebock mit zwei Balken (s 203) bzw. als Gatter mit Latten (s 208/220), nicht als Gerinne auf Böcken; der Trog ist nicht zu erkennen. Bei s 208 stehen zwei Zäune hintereinander zwischen Kamera und Figur. Auf dem Handy bei s 218 liegt die Figur hinter Riegel und Latten und ist nur noch als oranger Fleck zu sehen. Im Startbild s 8/12 sind es jetzt drei Querbalken vor der Figur: der Käfig ist verstärkt, wie R4 vorhergesagt hat.

**Vorschlag:** Den Holm als Trog mit sichtbarem U-Profil und Wasser bauen statt als zweiten Balken, die Latten weglassen. Für den Start den R3-Vorschlag (Gatter nicht zwischen Kamera und Figur). Holm gegen Käfig bleibt Nutzerentscheidung.

### mittel: Wurzeltreppen S1–S3 (desktop/verfolger_07_140.png, zusatz/verfolger_01_120.png; zoom/p140_treppe.png, p140_enden.png)

**Befund:** Teilweise behoben: Die lachsfarbenen Enden sind weg (Feld x 300–420 / 880–1000, y 470–600: 4070 → 307 Bildpunkte), die schwarzen Zacken an den Enden aus R3 ebenso; die Wurzeln sind dicker. Die Silhouette bleibt aber zwei schnurgerade Leisten über die ganze Breite mit braunen Bögen an der Setzstufe, die Enden als glatte U-Kehle. Liest sich als Bordstein oder Bank.

**Vorschlag:** Stufenkante aus mehreren Strängen, die die Linie um ±0,15 m brechen und nicht über die ganze Breite durchlaufen; die Enden in die Böschung einwachsen lassen statt als Kehle.

### leicht: Lösswände B/C (desktop/verfolger_01_030.png, 03_060, 05_090; zoom/p060_loess.png, p060_naht.png)

**Befund:** Haarstriche s 60 von 455 auf 180 (haar.py), im Feld x 100–260 / y 460–640 dunkle Nahtpunkte R3 9 / R4 121 / R5 0. Die Vorhänge sind jetzt kupferhelle, gleichmäßige Kämme, die an einer geraden Linie unter der Narbe beginnen, wie Fransen oder Haar. Die Rillen wirken unverändert wie eine Wischspur. Die rechte Wand ist glatt und blaugrau wie Schiefer oder eine Plane. Die Ursache der Nahtrisse ist ungeklärt; an dieser Stelle sind sie nicht mehr messbar.

**Vorschlag:** Vorhänge unregelmäßig in Länge und Dichte, direkt an der Narbe ansetzen, Ton näher an der Wand. Die Rillen schärfer und schmaler statt verwischt.

### leicht: Startbild s 8/12 und Lichtschächte (desktop/verfolger_00_008.png, holm/verfolger_00_012.png, desktop/verfolger_01_030.png)

**Befund:** Die steilen Lichtschächte fallen aus offenem Himmel, ohne Kronen darüber; sie wirken wie Scheinwerfer, bei s 30/72 auch quer vor dem Eichenstamm. Unverändert: U-Rinne links, Keiler hinter dem Gatter als Fächer, Kistensäule in der Mitte. Der Suhlgraben im Vordergrund bei s 12 zeigt ein Fleckenmuster wie Leopardenfell.

**Vorschlag:** Schächte nur dort, wo Kronen sie begründen (mit der Waldkante), sonst weglassen. Rinne als unregelmäßige Erosionsrinne, Bodenmuster in der Suhle gröber und schlammig.

### leicht: Fernkulisse, Torbuchen, Birken (desktop/verfolger_02_052.png, 04_072, 06_130, 13_280; seite/seite_00_040.png, seite_01_286.png; zoom/z286s_oben.png, p280_birken.png)

**Befund:** Unverändert: stammlose rosa und blaugraue Kronen am Horizont, ein grauer Riesenklecks oben rechts (s 52–72). Torbuchen als Schirmpinien, fern oliv. Birken in E als weiße Knochen oder Geweihe. In der Seitenansicht 286 lesen sich braune Kugeln über dem Hang als schwebend; ihre Höhe über dem Gelände ist weiter ungeprüft.

**Vorschlag:** Fernbäume mit Stammansatz im Gelände, Ton an den Fernwald angleichen; Birkenrinde mit dunklen Flecken; Torbuche als geschlossene Kuppel (Sichtliniensuche nötig).

### leicht: Tobel D übrige Teile (desktop/verfolger_08_186.png, 10_220, 11_240, 12_262; zoom/p262_ufer.png)

**Befund:** Die linke Wand ist glatt orange mit Polygonfacetten („Sandstein weich“) und wirkt wie Knete; links weder Birken noch Kupferfarn. Der Farn an der Südwand steht als orange Bumerang-Formen. Der Bach ist gerade und gleich breit, die Ufersteine liegen als Kette. Findlinge F1/F2 sind behoben (Blockgruppen, granitgrau, Moos).

**Vorschlag:** Sandstein mit Schichtbändern statt Facetten, Birken und Kupferfarn an der linken Kante, Farn als Polster ohne Spitzen, den Bach in Kurven und mit Steinen führen.

### leicht: Handy s 280 (handy/verfolger_02_280.png)

**Befund:** Unverändert und bekannt: Die Tastenraute verdeckt Nabe und rechte untere Hälfte des Mühlrads.

**Vorschlag:** Mühlrad auf dem Handyweg weiter zur Mitte oder höher setzen.

### leicht: Schlussbild s 290/296 und Teich (desktop/verfolger_14_296.png, zusatz/verfolger_03_290.png, seite/seite_01_286.png)

**Befund:** Das Ziel ist behoben: Das Portal steht seitlich und gibt die Figur bei s 290 frei. Auch der Vordergrund ist teilweise besser (Zaunrest, Busch, Stein, Schilf aus Halmen). Das untere Drittel bleibt aber leerer Rasen, der Teich ist flach mit weißem Saum; in der Seitenansicht ist die Teichfläche ganz mit weißen Sprenkeln übersät.

**Vorschlag:** Ufer mit Kante und Steinen statt Saum, Glitzern nur im Sonnenreflex. Im Auslauf mehr Vordergrund (Ufergras, Steine).

### Messungen

Bild-Jury L05, Runde 5, an HEAD 560a57d. Kopie per git archive unter abschluss/jury_r5/kopie, Import ohne Skriptfehler. Am Repo nichts geändert: git status leer.

GERENDERT (FOTO_SAAT=1, --fixed-fps 30, FOTO_WERTE)
- desktop: 15 Spielkamera-Stellen (8, 30, 52, 60, 72, 90, 130, 140, 186, 208, 220, 240, 262, 280, 296).
- zusatz: 44, 120, 196, 290. holm: 12, 203, 207, 212.
- seite: 40, 286.
- handy (FOTO_REDUZIERT=1, FOTO_TOUCH=1): 60, 218, 280.
- Budgetraster scan_a/scan_b: 75 Stellen, 4–300 alle 4 m.
- Dichte Reihen: dicht_c 150–172 und dicht_e 262–290, alle 2 m. Kalte Einzelstellen: 276 und 164.
- Alle rc 0, keine WARNUNG. Desktop, Handy und Seite sind byte-gleich mit den Bildern des Nachbesserers (l05_r4/bilder/e2_*).

URTEIL
L05 besteht neben L01 nicht. Der schwere Mangel „Gesamtbild“ bleibt, das Urteil hängt wie in R4 an K3 und der Waldkante. Neu ist ein mittlerer Bildfehler aus R4: die Sickerspuren werden schwarz gezeichnet. Die dokumentierte Budgetreserve ist rund fünfmal zu hoch angegeben.

BILDWERTE R5 GEGEN L01 (Skripte aus R4: werte.py, dazu rahmen.py)
- Luma 54,7–73,5 gegen 43,3–61,1.
- warm 0,41–0,50 gegen 0,18–0,42.
- kühl 0,13–0,25 gegen 0,20–0,35.
- Sättigung unten 166–201 gegen 157–186.
- flach oben 0,14–0,38 gegen 0,24–0,32.
- Himmel 0,08–0,20, in s 52–90 0,17–0,20, gegen 0,08–0,11.
- Gegen R3: Sättigung unten −9 bis −38 (z. B. s 30 von 227 auf 189), warm 0,43–0,61 → 0,41–0,50. s 8 ist heller geworden (Luma 66,4 → 73,5).
- Gegen den R4-Jurystand: alle 15 Werte decken sich mit der Tabelle in Doku R4.

ABGLEICH MIT l05_jury_runde3.md
Behoben:
- Findlingsgasse.
- Ziel/Portal: seitlich, Figur bei 290 frei.
- Fruchtkette am Wehr neben der Achse.
- Schwarze Zacken an den Treppenenden.
- Büschel der Nahblende.
- Reißverschluss-Spalt der Eiche nah.
- Pfahlköpfe: weitgehend, keine weißen Kappen mehr.

Teilweise:
- Lücken.
- Wurzeltreppen: lachsfarbene Enden 4070 → 307 Bildpunkte.
- Nahblende: der Riegel mit Wurzelschlaufen steht bei s 90 weiter quer im Vordergrund.
- Tobel D.
- Lösswände: Haar 455 → 180; Nahtpunkte im Feld s 60 R3 9 / R4 121 / R5 0.
- Licht und Farbe.
- Schlussbild.

Nicht behoben:
- Gesamtbild (schwer).
- Torbuchen.
- Fernkulisse.
- Startbild: mit dem Holm verschärft.
- Joch als Gatter.
- Birken.
- Ufersteine.
- Handy-Mühlrad.

Verschlechtert bzw. neu:
- Sickerspuren schwarz (s 196: 407 → 1314 Strichpunkte, s 240: 856 → 2235, Seite 286: 0 → 767).
- Eiche fern als Pilzhut, mit Sprung zwischen s 68 und 72.

BUDGET
Jury-Reihe:
- Rechner höchstens 313 Draw-Calls (s 280), 733 782 Primitive (s 186), 107,6 MB.
- Handy höchstens 294 Draw-Calls (s 280), 633 591 Primitive (s 218), 83,0 MB.
- Seite: 251 / 583 533 (s 40) und 197 / 397 417 (s 286).
- Zusatz: 44 223/500 993, 120 258/609 803, 196 270/727 607, 290 268/666 986.
- Holm: 12 203/440k, 203 253/672k, 207 263/698k, 212 260/701k.

Raster und dichte Reihen:
- Höchstwert 747 074 bei s 276 (dicht ab 262), Reserve 2 926.
- s 274: 743 526. s 164: 736 303 im Raster, 733 885 dicht.
- Kalt angefahren: 276 695 134, 164 687 404.
- Draw-Calls im Raster höchstens 313.
- Alle Grenzen (≤ 500 / ≤ 450 Draw-Calls, ≤ 750k Primitive, ≤ 140 MB) sind eingehalten. Die Reserve beträgt aber nur rund 0,4 %, nicht wie dokumentiert 16k.

UNGEPRÜFT
- Bewegung: Schilf, Weißwasser, Lichtschächte, Holm. Der Wechsel der Eiche ist nur über Standbilder im 4-m-Raster belegt.
- Ob die Sickerspur auf echter GPU oder im Web-Export ebenfalls schwarz ist.
- Höhe der Kugeln in Seite 286.
- Budget beim Rückwärtslaufen und nach dem Respawn an CP5.
- Ein Lauf von Hand.

Zur Spielfigur: Die L01-Vergleichsbilder (vorher/l01) zeigen eine andere Figur als das aktuelle L05. Ein Vergleich der Figur ist so nicht möglich; die Frage liegt ohnehin beim Nutzer (cash_banooka_rc.glb).

Daten, Skripte und Zooms unter /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/jury_r5/: werte_r3_r5.txt, werte_r4_r5.txt, werte_l01.txt, rahmen.txt, scan.tsv, skripte/, zoom/.
