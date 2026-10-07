# Nutzerentscheidungen P0 (verbindlich, gehen allen Entwürfen und dem Baukastenplan vor)

- R1 (L02): **Spurbindung in 2D: JA.** In der Seitenansicht wird die Eingabe auf die Wegachse gelegt (Seitenanteil ≥ 0,5). Reine Steuerung, keine Physikänderung. CLAUDE.md bekommt dazu eine Zeile (Steuerung).
- R2 (L04): **tempo_max 19 → 15 und Rastplatz-Tempo: JA.** reiter.gd bleibt unverändert; Level04.tscn setzt tempo_max 15, das Level setzt an jedem Rastplatz tempo_start.
- R3 (L05): **Slide-Sprung als Kür: JA.** Slide unter Durchlässen ist Pflicht; der Slide-Sprung belohnt (Abkürzung/Geheimnis), wird nie erzwungen.
- R4 (alle): **Modellbudget: bis ~24 neue CC0-Modelle** (nicht nur 9). G4 übernimmt die volle Wunschliste aus den vier Entwürfen (dedupliziert, rund 24 Dateien, Quaternius/Kenney, CC0), Ersatzlösungen aus baukasten.md §4 Nr. 10 entfallen, wo das echte Modell kommt. .pck-Zuwachs messen und berichten.
- R5 (Figur cash_banooka_rc.glb): offen, wird separat mit dem Nutzer geklärt; die Datei wurde vom Nutzer selbst eingecheckt. Nicht anfassen.

---

# Level 04 „Katzensprung“ – Neubau: Ritt durch den Windbruch

> **Stand:** verbindlicher Entwurf, noch nicht gebaut. Grundlage ist HEAD `93b8816`; `052641f` weicht davon nur in `.gitignore` ab. Er führt drei Konzepte (Spiel, Bild, Technik) und zwei Jury-Urteile zusammen.
> **Rechnungen:** Nachgebaut sind `reiter.gd:168-186, 297-326`, `corridor_camera.gd:366-461` und die Kurve mit festen Griffen (G3), alle bei 60 Hz. Die Skripte liegen unter `/tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/l04_neubau/`: `verlauf.py` (Kurve und Ringschluss), `ritt.py` (Sprünge), `kamera.py` (Kamera und Plan), `marken.py` (alle Marken) sowie `pruef_alles.py` und `pruef_*.py` (Prüfungen).
> **Was nicht gelaufen ist:** In Godot ist nichts gelaufen, gerendert wurde nichts. Die gebackene Godot-Kurve kann um bis zu ±0,5 m abweichen (ungeprüft). Alle s-Werte sind Plan-s; die nachgebaute Bezierkurve liegt höchstens 0,2 m darüber.

---

## 0. Pitch

Nach dem Sturm reitet man auf der Wildkatze durch einen umgestürzten Riesenwald:
- unter dem quer liegenden Kreuzstamm hindurch;
- auf einem Rampenstamm hinauf;
- über die gebrochenen Brückenstämme, zuletzt mit einem Doppelsprung als Weitsprung;
- über die Bruchkante hinab ins Farnbett, durch die abgebrochene Krone in die Kehre;
- auf dem Kreuzstamm quer über die eigene Spur von vor 23 Sekunden;
- über den größten Riesen bis durch den Spalt in seinem Wurzelteller.

**Bildregel: „Der Wald liegt.“** Waldboden heißt lenken, silbergraue Rinde heißt springen, cremeweißes frisches Bruchholz heißt Lücke. Das Level ist hell und offen. Das Totholz ist silbergrau, im Osten zieht die dunkle Sturmwand ab.

L04 ist das einzige Level, das die eigene Spur kreuzt (X, 8,8 m Höhenunterschied), und das einzige, in dem der Wald liegt statt steht.

---

## 1. Entscheidungen

| # | Entscheidung | Herkunft | Warum |
|---|---|---|---|
| E1 | Grundriss als **Haarnadel mit Kreuzung**. Der Ringschluss ist mit drei Unbekannten (Kehrenwinkel, Rückweglänge, Bogen B2) gelöst. X unten liegt bei s 66,0, X oben bei 407,1. Im Plan liegen beide 0,1 m auseinander, sie kreuzen sich mit 90°, der Höhenabstand ist 8,8 m. | Spielentwurf §0.1, neu gerechnet | Die Schleife aus der Vorgabe schließt sich nicht (`l04_verlauf/schleife.py`). |
| E2 | **Kurve 479,2 m**, Ziel bei s 469,8, Ritt 33,1 s. | eigene Rechnung | Vorgabe ≤ 480 m |
| E3 | **Tempoverlauf (G4) als Minimaleingriff:** `tempo_anstieg` 0,28 bleibt, `tempo_max` 19 → **15**. An jedem Rastplatz setzt das Level `_reiter.tempo_start` auf das Tempo des Erstlaufs an dieser Stelle. **Rückfrage R1.** | Spielentwurf §6, Jury TB 2 | Das Tempo ist damit eine feste Funktion von s: v(s) = min(15, √(121 + 0,56·(s−2))). Ohne das ist kein Pflicht-Doppelsprung regelkonform baubar (Jury SK 4). `reiter.gd` bleibt unverändert, L17 ist nicht berührt. |
| E4 | **Eine Datentabelle** in `level04.gd`. Kameraplan, Stimmung, Rastplätze, Fruchtbögen und Proben lesen nur aus ihr. | Jury TB 1, SK 3 | Drei Konzepte hatten drei Geometrien. |
| E5 | **Durchschlupf:** Unterkante 6,0 m, Kreuzstamm Ø 3,0, Bahn oben 8,8. Tiefe Kamera bis Reiter-s X+17. Kameradeckel als Rückfall. | Bild B1, Jury SK 2, TB 3 | Gerechnet steht die Kamera höchstens bei 5,14 m. Die Figur reicht im Doppelsprung bis 5,46 m. |
| E6 | **Rampen ≤ 20 %:** C 18,5 % (größte Steigung 19,7 %), Auffahrt F 18,5 % (19,4 %), mit eigenen 4-m-Übergängen. | K4 (`level01-neubau.md:732`), Jury TB 3 | Das Blickziel liegt sonst tief im Hang (`corridor_camera.gd:442`). |
| E7 | **`Stammbahn` als neues Bauteil:** ein Kreisstamm mit ebener Kappe ≤ 0,15 r genau auf Kurvenhöhe. `Riesenstamm.liegend` bleibt unverändert. | Bild B3, Jury TB 4 | Der Reiter sitzt quer überall auf Kurve + 0,04 (`reiter.gd:458`). |
| E8 | **Seitengrenzen:** Boden 4,4 (Weg 11 m), Rinde 0,5, Riese R4 1,0. Vor jedem Stammfuß liegt ein Trichter ≥ 12 m. | Jury SK 8, TB 11 | Die Kappe ist bei Ø 3,0 nur ±0,79 m eben. Die Katze ist ±0,40 m breit (`katze.gd`: Brust 0,38 × 1,05). |
| E9 | **Kein Kollisionskörper an Stämmen, Teller oder Hindernissen.** Bot und LevelCheck bekommen ein unsichtbares Band auf **Wert 16** über allen Boden- und Rindenstücken, nicht über den Lücken. | Jury TB 5, TB 13, Technik B10 | Der Kamerastrahl sieht es nie. Die Probe „Lücke frei zwischen +3 und −4 m“ hält. |
| E10 | **`sicht_maske = 8`** in L04. In der Kamerabahn steht nichts Sichtbares (KR1). | Technik §4, Jury SK 1 und 6 | Kisten (Ebene 1, `kiste.gd:131`) zogen die Kamera auf Rampen vor die Figur. |
| E11 | **Kameraplan nach Reiter-Strecke:** Verfolger, tief (Durchschlupf), Brücke (D, 1,2 m höher) und erhöht (Kreuzung). Alle Blenden dauern ≥ 1,05 s. Kein 2D, kein Hochblick, kein Rückblick. | Raumbogen, Leitidee | Die Kamerazone fällt an jeder Naht aus (F1). |
| E12 | **Horst** (gefahrloser Doppelsprung) über durchgehendem Stamm D2 bei s 162,5–165, q −1,3, Kistenmitte h 5,2. Dazu die Brücken-Kamera. | Leitidee, Jury SK 10, TB 19 | Mit dem Verfolger kämen die Kisten der Kamera auf 0,82 m nahe, mit der Brücken-Kamera bleiben 1,97 m. |
| E13 | **Rastplatz vor dem Doppelsprung:** CP4 bei s 153,3 liegt 1,50 s vor dem Fenster von L3. **L2 entfällt;** D2 trägt Rastplatz, Horst und Anlauf. | Jury SK 9, TB 18 | Die Länge ist sonst nicht unter 480 m zu halten. |
| E14 | **Wurzelteller mit oben offenem Spalt** (unten ≥ 6 m, oben 10–12 m), dazu der normale Verfolger. Der „Satz durch den Teller“ ist die Lücke L5 an der Rückseite. | Bild B2, Jury SK 5, TB 7 | Ein geschlossenes Loch ist für die Kamera nicht sicher. |
| E15 | **Hindernis-Code:** Was steht, ist ≥ 3,5 m hoch und wird umfahren (die Zone ist 3,5 hoch). Was liegt, ist 0,7–1,0 m hoch und ≤ 1,0 m tief und wird übersprungen. | Jury SK 11, TB 12 | Ein Doppelsprung überwindet 2,2 m (Fenster 0,33 s), 3,5 m nicht. |
| E16 | **Sturm aus West:** Alle Kronen liegen nach Osten, alle Teller im Westen. R1 ist ein Stammbruch (Stumpf bei J3), die Auffahrt R5 ein Bruchstück. | Jury TB 19 | Behebt den Widerspruch zwischen R1 und R4. |
| E17 | **Sonne im SSW** (Azimut 200°, Höhe 32°), `fog_sun_scatter` ≤ 0,1. Der Spalt leuchtet über einen Lichtschacht. | Jury TB 9 | L01 hat das Streulicht schon abgeschafft (`level01/stimmung.gd:12-17`). |
| E18 | **Wahrzeichen je Abschnitt** statt „Teller ständig sichtbar“. | Jury TB 10 | Gerechnet ist der Teller bei s 50–265 nicht im Bild. |
| E19 | **Kehre „durch die Krone“, Rückweg „durch die Runse“.** In der Runse liegt das Stück, das in L3 fehlt, mit seinem Splitterbalken als Hürde. | Jury SK 12, Bild §3 | Gibt dem Rückweg einen eigenen Moment, statt Füllstoff zu sein. |
| E20 | **Knicke** ≤ 20° je Stoß oder Lücke, Drehrate ≤ 45°/s: R ≥ 18 m bei 14–15 m/s. | Jury SK 13 | Im Spielentwurf waren es 70°/s. |
| E21 | **Tipp-Regel:** Jedes Pflichtfenster hat gehalten ≥ 0,33 s und mit 6-Bilder-Tipp ≥ 0,217 s. | Jury SK 7 | Auf dem Touchscreen wird getippt (CLAUDE.md). |
| E22 | Rastplätze melden `GameState.checkpoint_gesetzt.emit()` direkt. | Jury SK 14, TB 19 | Ohne das ist „alle Kisten“ nach einem Tod nicht mehr zu schaffen. |
| E23 | Neue Modelle **höchstens 5** (BirchTree_1/3, CommonTree_Dead_3, Rock_1/3). | Jury TB 16 | Grenze rund 25 (`natur2/LIESMICH.md:102`). |

**Verworfen:**
- L2 (5-m-Lücke): hält die Tipp-Regel nicht und kostet Länge.
- Der geschlossene Tellerloch-Durchritt und die tiefe Kamera am Teller.
- Die Wurzelschwelle im Loch; sie ist durch L5 ersetzt.
- `absturzzonen()`: Die Zone des oberen Astes reicht bis y 3,2 in den Durchschlupf (`korridor_level.gd:835-851`).
- Die Option `ruecken` in `Riesenstamm.liegend` (TB 4).
- Gegenlicht mit Streulicht im Finale.
- Hindernisse im tiefen Kameraabschnitt B: Die Kamera fährt dort auf 3,0 m und streifte Stümpfe von 3,5 m.
- Der Halt unter X auf Grenze 2,0. Mit `strecke_von` gibt es dafür keinen Grund mehr (TB 11).

**Jury-Befunde, die keine Mängel sind (begründet):**
- **SK 10, Horst lehrt den Druck im Scheitel:** Der Horst braucht den zweiten Druck bis +26 Bilder (gerechnet). L3 nimmt ab Fenstermitte +0,28 bis +0,62 s. Wer am Horst gelernt hat, kommt also über L3. Die Früchte über L3 zeigen den späten Druck als Weite obendrauf.
- **TB 19, Raumregel „Einzelsprünge ≤ 3,0 m“:** Sie gilt zu Fuß. Im Ritt gelten Zeitfenster (E21), dokumentiert in §6.2.

---

## 2. Feste Größen und Rechenwerte

**Physik:** unverändert (CLAUDE.md). `JUMP_V` 12,2, `DJUMP_V` 10,5, G −38, `JUMP_CUT` 0,45.

**Reiter:**
- Kapsel r 0,5, Höhe 1,9, Mitte 0,95, Fuß bei Kurve + 0,04 (`Reiter.tscn:7-9`, `reiter.gd:458`).
- Die Figur ragt 2,20 m über den Ursprung (Jury, gemessen).
- Lenkung 9 m/s, Trägheit 9/s (`reiter.gd:31-34`). Gelenkt wird auch in der Luft (`_lenken` läuft immer).

**Sprünge des Reiters** (Weite ab dem letzten Bodenbild = v × Flugzeit):

| v (m/s) | einfach, gehalten (0,633 s) | Tipp 6 Bilder (0,517 s) | Doppel, bestes Timing (+33 Bilder, 1,167 s) | Doppel im Scheitel (+19, 1,0 s) | Doppeltipp (+28, 1,0 s) |
|---|---|---|---|---|---|
| 11 | 6,97 | 5,68 | 12,83 | 11,0 | 11,0 |
| 12 | 7,60 | 6,20 | 14,00 | 12,0 | 12,0 |
| 13,5 | 8,55 | 6,97 | 15,75 | 13,5 | 13,5 |
| 14 | 8,87 | 7,23 | 16,33 | 14,0 | 14,0 |
| 15 | 9,50 | 7,75 | 17,50 | 15,0 | 15,0 |

- **Scheitel:** einfach 1,86, Tipp 1,35, Doppel 3,22.
- **Höcker beim späten Doppelsprung (+33):** 1,86 nach 4,43 m, 2,15 nach 11,20 m (bei 14 m/s).
- **Fenster einer Lücke:** Flugzeit − L/v.
- **Kiste:** Trefferzone 1,15 × 1,9 × 1,15, Netz 1 × 1 × 1 (`Kiste.tscn`). Mit Mitte h 5,2 trifft nur der Doppelsprung: Der Kopf kommt einfach auf 3,80, die Zone beginnt bei 4,25.

**Tempo (E3):**

| s | 10 | 38 | 109,5 | 143,6 | 181,2 | ab 187,7 |
|---|---|---|---|---|---|---|
| v (m/s) | 11,2 | 11,9 | 13,5 | 14,2 | 14,9 | 15,0 |

**Kamera:**
- Verfolger 6,4 / 12,5 / 9,0 (wie heute in `Level04.tscn`).
- Ort geglättet mit τ 0,145 s (`corridor_camera.gd:458`), Höhe träge mit 2,6/s (`:396`). Das Blickziel liegt auf Figurhöhe + 1 und ist ungeglättet (`:442`).
- Sichtfeld 60° senkrecht, 91,4° waagerecht bei 16:9, `far` 200.
- Neigung: Verfolger 14°, tief 6°, Brücke 15,5°, erhöht 28,6–30,2°, bergab in E1 25,9°, auf Rampen 8°.

---

## 3. Verlauf

- Gebaut mit **G3**: Gerade mit Griff = Sehne/3, Bogen mit Griff = 4/3·tan(Δ/4)·R, je ≤ 30°.
- Stämme sind im Grundriss gerade und linear steigend. Übergänge sind 4-m-Stücke mit der Knotensteigung des Stamms.
- In Fall-Lücken fällt die Kurve als Bogen (Steigung 0 an der Absprungkante).
- **Nicht** über `kurve_aus_punkten`, das überschwingt (`level_werkzeuge.gd:493-502`).
- Start (0 | 0 | 0), Kurs 340°. Kurs 0° = Norden (−z), 90° = Osten.

| Stück | s (Plan) | Ende x / y / z | Kurs | Wende, R | Steigung (Nachbau) | Inhalt |
|---|---|---|---|---|---|---|
| A1 | 0–20 | −6,8 / 0 / −18,8 | 340° | gerade | 0 | Start s 2 |
| A2 | 20–50 | −12,0 / 0 / −48,2 | → 0° | +20°, R 86 | 0 | |
| A3 | 50–66 | −12,0 / 0 / −64,2 | 0° | gerade | 0 | **X unten s 66,0** |
| B1 | 66–72 | −12,0 / 0 / −70,2 | 0° | gerade | 0 | |
| B2 | 72–99,3 | −0,5 / 0 / −93,8 | → 52,1° | +52,1°, R 30 | 0 | Trichter 87,3–99,3 |
| Cu, C, Cv | 99,3–130,3 | 23,6 / 5,0 / −112,6 | 52,1° | gerade | 18,5 % (max. 19,7 %) | R2 Rampenstamm |
| J1 | 130,3–136,6 | 29,2 / 5,15 / −115,6 | → 72,1° | +20°, R 18,0 | 1–3 % | Stoß R2 → R3, Moossattel |
| D1 | 136,6–143,6 | 35,8 / 5,35 / −117,7 | 72,1° | | 3 % | |
| **L1** | 143,6–147,6 | 39,7 / 5,5 / −118,6 | → 83,1° | +11°, R 20,8 | | Lücke 4,0 |
| D2 | 147,6–181,2 | 73,1 / 6,4 / −122,7 | 83,1° | | 3 % | CP4, Horst |
| **L3** | 181,2–192,4 | 84,2 / 6,8 / −122,1 | → 103,1° | +20°, R 32,1 | | Doppelsprung 11,2 |
| D4 | 192,4–204,4 | 95,9 / 7,0 / −119,3 | 103,1° | | 2 % | |
| **L4** | 204,4–208,4 | 98,9 / 4,6 / −118,3 | → 115,1° | +12°, R 19,1 | Fall 2,4 | Bruchkante |
| E1, Eu | 208,4–224,4 | 112,7 / 0 / −111,8 | 115,1° | | −33,6 % | Bruchstück ins Farnbett |
| Kehre | 224,4–292,0 | 102,1 / 0 / −64,2 | → 270° | +154,9°, R 25 | 0 | durch die Krone |
| Rückweg | 292,0–346,7 | 47,5 / 0 / −64,2 | 270° | gerade | 0 | Runsen-Senke −1,2 m bei 308–328 (nicht im Nachbau) |
| Ru, Rampe, Rv | 346,7–397,0 | −2,0 / 8,8 / −64,2 | 270° | gerade | 18,5 % (max. 19,4 %) | R5 Auffahrt |
| K1 | 397–407 | −12,0 / 8,8 / −64,2 | 270° | | 0 | **X oben s 407,1 (Kurve)** |
| K2 | 407–417 | −22,0 / 8,8 / −64,2 | 270° | | 0 | |
| J3 | 417–423,5 | −28,5 / 9,2 / −63,7 | → 262° | −8°, R 46,6 | ≤ 9 % | Stumpf R1 und Astgabel R4 |
| G | 423,5–453,5 | −58,2 / 9,2 / −59,6 | 262° | | 0–2 % | R4 Kronenlauf |
| H1 | 453,5–459,5 | −64,1 / 9,2 / −58,7 | 262° | | 0 | Tellerspalt |
| **L5** | 459,5–464,0 | −67,9 / 6,8 / −58,2 | 262° | | Fall 2,4 | Satz aus dem Spalt |
| H2 | 464,0–470,0 | −73,8 / 6,6 / −57,4 | 262° | | −3 % | **Ziel 469,8** |
| Hu, H3 | 470–479,0 | −82,5 / 4,5 / −56,1 | 262° | | −30 % | nur für die Kamera (Kurve 479,2) |

- **Abstände im Grundriss:** Außer an X liegen alle Wegstücke ≥ 19,5 m auseinander (`zeige.py`).
- **Ebenen:** Boden 0 (A, B, Kehre, Rückweg), Stämme 5,0–7,0 (C, D), Kreuzung 8,8 (R1), Kronenlauf 9,2 (R4).

---

## 4. Abschnittstabelle

| s | Abschnitt | Ebene | Grenze | Kamera | Inhalt |
|---|---|---|---|---|---|
| 0–46 | **A Sturmlichtung** | 0 | 4,4 | Verfolger | Stumpf 10 (frei), Fruchtbogen 13–18, Halbstamm 23, Stumpf 30, **Moosstamm 38**, CP1 46 |
| 46–99 | **B Unterm Riesen** | 0 | 4,4 → Trichter 0,5 | **tief** (40→54 … 83→97) | keine Hindernisse; Torstümpfe außerhalb der Bahn; **Durchschlupf X 66**; CP2 87 |
| 99–130 | **C Rampenstamm** | 0 → 5,0 | 0,5 | Verfolger | Stummel 109,5 und 119, CP3 121,5 |
| 130–208 | **D Brückenstämme** | 5,0–7,0 | 0,5 | **Brücke** (153→168 … 215→231) | **L1 4,0**, CP4 153,3, Horst, **L3 11,2 doppelt**, **L4 4,0 mit Fall** |
| 208–292 | **E Bruchkante und Kehre** | 4,6 → 0 | 0,5 → 4,4 | Verfolger | E1 abwärts, CP5 214,7, Kronengasse: Äste 240/262/284, Hochast 251, Hochastpaar 273 |
| 292–407 | **F Kreuzung** | 0 → 8,8 | 4,4 → Trichter 0,5 | Verfolger, **erhöht** (376→392 … 413→429) | CP6 292,5, Runse mit Splitterbalken 318, Stümpfe 327/336, Auffahrt R5, **X 407** mit Lebenskiste |
| 407–453 | **G Kronenlauf** | 8,8–9,2 | 0,5 → 1,0 | Verfolger | CP7 411, Hochstummel 431, Ast 440, Hochstummel 448 |
| 453–479 | **H Wurzelteller** | 9,2 → 6,6 | 1,0 | Verfolger | Spalt, **L5 4,5**, Ziel 469,8 |

---

## 5. Abschnitte im Einzelnen

### A · Sturmlichtung (0–46)

**Spiel:**
- Stumpf (q +2,8) bei s 10: frei bei q 0, er zeigt nur „stehendes Holz = vorbei“.
- Fruchtbogen 13–18: der erste gefahrlose Sprung.
- Kisten links (20,5/22,1, q −2,5) locken an den Halbstamm (23, q −0,3…+5,5, 0,7 m) vorbei. Wahl: links vorbei oder springen.
- Stumpf (30, q +0,8) sperrt die Mitte um 0,4 m. Wer schon links ist, ist vorbei.
- **Moosstamm** 0,7 m über die ganze Breite bei s 38: Fenster 0,389 s (Tipp 0,254).

**Bild:**
- Breite Gasse durch alten Windbruch, Reisigwälle bei |q| 6,0.
- Pfützen in Wurzelkuhlen; Böen tragen Laub quer.
- Wahrzeichen: Kreuzstamm voraus (+11° → 0°, 69 → 32 m), Teller links (−27°, 88 m).
- Die Lebenskiste auf X funkelt über der Stammkante.

### B · Unterm Riesen (46–99)

**Spiel:**
- Keine Hindernisse: In der tiefen Kamera (3,0 m) wäre jeder Körper über 1,8 m in der Bahn ein Kameraschaden.
- Lenken lohnt sich: Kisten 58/59,6 bei q −1,5 und 74/75,6 bei q +2.
- Die Fruchtreihe auf q 0 ist die „eigene Spur“ für den Blick von oben.
- Trichter 87,3–99,3; die Früchte ziehen zur Mitte.

**Bild:**
- **Torkomposition:** Erde und Halme nah, Torstümpfe bei q ±6,5 (nur Optik).
- Der Kreuzstamm als dunkles Dach. Darunter ein kühler Schattenkeil (Licht 0,85 bei 60–72), dahinter die helle Lichtung.
- Unterkante des Kreuzstamms ≥ 6,0 auf ganzer Wegbreite, gemessen am gebauten Netz.

### C · Rampenstamm (99–130)

**Spiel:**
- R2 liegt mit dem Wurzelende im Wurzelhügel und steigt mit 18,5 %.
- Stummel 0,7 m bei 109,5 und 119, Fenster 0,42 s. Der erste liegt 0,87 s nach dem Ende der Kamerablende (Jury SK 8).

**Bild:**
- Aufstieg aus dem Schatten ins Licht, Seitenlicht.
- Die Bahn ist silbern, die Flanken dunkel mit Flechte.
- Die Stummel sind dunkel und oben hell gebrochen.

### D · Brückenstämme (130–208)

**Spiel:**
- J1: Moossattel, R2 liegt auf R3.
- **L1 4,0 m:** Fenster 0,351 s, Tipp 0,234.
- CP4 bei 153,3, dann Kisten 154,5/156.
- **Horst:** 3 Kisten bei 162,5/163,75/165, q −1,3, h 5,2, verkeilt in **einer** Aststange bei q −2,2. Absprung bei 150–161,8, zweiter Druck +12…+26 Bilder; man landet vor dem L3-Fenster.
- **L3 11,2 m doppelt:** Fenster 0,414 s, Doppeltipp 0,247. Der Einfachsprung fehlt um 1,78 m.
- **L4 4,0 m, Fall 2,4:** Fenster 0,367, Tipp 0,250. Die späteste L3-Landung (198,6) liegt vor dem L4-Fenster (199,2).

**Bild (Schlüsselbild):**
- Sonnige Silberstämme vor der dunklen Sturmwand im Osten, Rückenlicht.
- Darunter die dunkle Runse, 3–5 m tiefer, mit Rinnsal.
- Lücken nach Lücken-Code (§8.1). Bei L3 fehlt sichtbar ein Stück.

### E · Bruchkante und Kehre (208–292)

**Spiel:**
- E1 ist das Kronenbruchstück von R3: −33,6 % hinab ins Farnbett, Grenze 0,5 → 4,4 auf 12 m.
- CP5 bei 214,7. Danach die Kronengasse bei 15 m/s in R 25:
  - Äste 0,8 m bei 240, 262 und 284 (je 0,396 s);
  - Hochast 251 bei q +1,0 (links vorbei; rechts davon die Innenbahn, §6.3);
  - Hochastpaar 273 als Tor (Mitte frei).
- Alle Hindernisse stehen 1,5 s vor ihrem Fenster ≤ 26° neben der Bildmitte (halbes Sichtfeld 45,7°).

**Bild:**
- Splitterkrone an der Bruchkante; bei der Landung eine Laubwolke.
- Im Farnbett liegen die Äste der Krone radial über der Kehre.
- Kurz Gegenlicht bei Kurs ≈ 200°. Ab s ≈ 274 kommen Kreuzstamm und Teller zurück ins Bild.

### F · Kreuzung (292–407)

**Spiel:**
- CP6 bei 292,5.
- Runse: Senke −1,2 m auf 20 m (≤ 19 %); in der Sohle der **Splitterbalken** 0,8 m bei 318.
- Stumpf 327 (q −1,0) und 336 (q +1,0) als Slalom vor dem Trichter 334,7–346,7.
- Auffahrt R5 mit 18,5 %, oben der Moossattel auf R1, **X 407** mit Lebenskiste.

**Bild:**
- Rechts die Runse hinauf zu den Brückenstämmen; dort fehlt das Stück, das jetzt hier liegt.
- In der erhöhten Kamera liegt die eigene Spur B voll im Bild (s 380–390: 46 von 46 Punkten, s 404: 35 von 46).
- X unten ist bis s 405,8 zu sehen, also bis 1,3 m vor der Kreuzung.

### G · Kronenlauf (407–453)

**Spiel:**
- CP7 bei 411.
- R4 (Ø 5,0 → 4,0, Grenze 1,0).
- Hochstummel bei q ±0,6 sperren die Mitte um 0,25 m: Slalom 431 (links) und 448 (rechts).
- Dazwischen der Ast 1,0/0,8 bei 440: 0,365 s, Tipp 0,217.

**Bild:**
- Hoch über allem, der Teller wächst mittig (−3° … 0°).
- Die letzten 18 m liegen im Tellerschatten.

### H · Wurzelteller (453–479)

**Spiel:**
- Durch den Spalt; **L5 4,5 m, Fall 2,4** an der Tellerrückseite: 0,333 s, Tipp 0,217.
- Späteste Landung 469,0, **Ziel 469,8**. Liegt das Ziel früher, friert der Reiter in der Luft ein (`reiter.gd:180-182`).

**Bild:**
- Dunkler Teller (18–20 m), Lichtschacht durch den Spalt.
- Hinter dem Teller der Erdkegel über der Wurzelkuhle mit Tümpel.
- Die Kamera bleibt im Spalt stehen (Bahn + 6,4) und rahmt das Ziel; Neigung 21°.

---

## 6. Spiel

### 6.1 Lehrfolge

1. Stumpf frei: vorbei.
2. Fruchtbogen: springen, gefahrlos.
3. Halbstamm: lenken **oder** springen.
4. Stumpf: lenken, Pflicht.
5. Moosstamm: springen, Pflicht.
6. B: Durchschlupf als Schauplatz, Lenken für Kisten.
7. Rinde: Stummel springen.
8. L1: erste Lücke.
9. Horst: Doppelsprung gefahrlos.
10. L3: Doppelsprung als Weitsprung, Pflicht.
11. L4: Satz hinab.
12. Kronengasse: lenken und springen gemischt bei 15 m/s.
13. Runse und Slalom.
14. Kreuzung: Belohnung und Blick.
15. Kronenlauf: Slalom auf 2 m Rinde und Ast.
16. L5: Satz durch den Teller.

### 6.2 Sprungtabelle (Pflicht)

Regel: gehalten ≥ 0,33 s, Tipp (6 Bilder) ≥ 0,217 s, Doppeltipp ≥ 0,20 s. Beim Doppelsprung fehlt der Einfachsprung um ≥ 1,5 m. Die Fenster sind ab dem letzten Bodenbild gerechnet.

| Stelle | s | Art | v | Fenster gehalten | Tipp | Druck-s / Anmerkung |
|---|---|---|---|---|---|---|
| Moosstamm | 38 | Hürde 0,7 / Tiefe 1,0 | 11,9 | 0,389 | 0,254 | 32,2–36,8 |
| Stummel C1 | 109,5 | Hürde 0,7 / 0,8 auf 18,5 % | 13,5 | 0,421 | 0,285 | 102,7–108,3 |
| Stummel C2 | 119 | Hürde 0,7 / 0,8 | 13,7 | 0,422 | 0,286 | 112,1–117,8 |
| L1 | 143,6–147,6 | Lücke 4,0 | 14,2 | 0,351 | 0,234 | späteste Landung 152,6 |
| **L3** | 181,2–192,4 | Lücke 11,2, doppelt | 14,9 | **0,414** | 0,247 (Doppeltipp) | 175,0–181,4; zweiter Druck 0,28–0,62 s ab Fenstermitte; Einfachsprung fehlt 1,78 m |
| L4 | 204,4–208,4 | Lücke 4,0, Fall 2,4 | 15 | 0,367 | 0,250 | 199,2–204,7 |
| Äste der Kehre | 240 / 262 / 284 | Hürde 0,8 / 1,0 | 15 | 0,396 | 0,257 | |
| Splitterbalken | 318 | Hürde 0,8 / 1,0 in der Senke | 15 | 0,396 | 0,257 | 310,6–316,5 |
| Ast G | 440 | Hürde 1,0 / 0,8 | 15 | 0,365 | 0,217 | 432,8–438,3 |
| L5 | 459,5–464,0 | Lücke 4,5, Fall 2,4 | 15 | 0,333 | 0,217 | 454,8–459,8 |

**Lenk-Pflichten:**

| Stelle | s | Sperrt die Mitte um |
|---|---|---|
| Halbstamm | 23 | 0,8 m |
| Stumpf | 30 | 0,4 m |
| Hochast | 251 | 0,2 m |
| Stümpfe | 327 / 336 | je 0,2 m |
| Hochstummel | 431 / 448 | je 0,25 m |

### 6.3 Geheimnisse und Angebote

| | Ort | Weg | Inhalt |
|---|---|---|---|
| Angebot Horst | D2 162,5–165, q −1,3, h 5,2 | links lenken und doppelt springen | Kiste, FRUCHT, Kiste (die 2. Holzkiste ist im Zeitmodus eine Zeitkiste) |
| S1 Innenbahn | Kehre 249,5–252,7, q +3,8 | rechts am Hochast 251 vorbei | Kiste, FRUCHT, Kiste |
| Versprechen | Lebenskiste auf X bei 407 | von A und B aus als Funkeln sichtbar | LEBEN |

### 6.4 Zählung

| | A | B | C | D | E | Kehre | F | G | Summe |
|---|---|---|---|---|---|---|---|---|---|
| Kisten | 6 | 6 | 4 | 7 | 3 | 9 | 8 | 3 | **46** |
| davon NORMAL / FRUCHT / SCHUTZ / LEBEN | 4/2/–/– | 4/2/–/– | 2/2/–/– | 5/2/–/– | 2/–/1/– | 5/4/–/– | 5/2/–/1 | 1/1/1/– | **28 / 15 / 2 / 1** |
| Früchte | 16 | 12 | 8 | 24 | 16 | – | 14 | 10 | **≈ 100** |

**Kistenorte (s, q):**
- A: 5,5 / 7,1 / 8,7 (0); 20,5 / 22,1 (−2,5); 45 (0).
- B: 54 (0); 58 / 59,6 (−1,5); 74 / 75,6 (+2); 84 (0).
- C: 100 / 101,6; 127 / 128,6.
- D: 132,5 / 134,1; 154,5 / 156; Horst.
- E: 221,5 / 223,1; SCHUTZ 226.
- Kehre: 229,5 / 231; Innenbahn; 271 / 272,6; 293,5 / 295,1 (+2).
- F: 326,5 / 328,1 (+1,8); 338 / 339,6; Rampe 358 / 363 / 368; LEBEN 407.
- G: SCHUTZ 412,5; 425 / 426,6 (−0,6).

**Regeln für Kisten:**
- Keine Kiste in einem Sprungfenster oder in der Landestrecke einer Pflichthürde.
- Schwebend sind nur die drei Horst-Kisten (`schwebt = true`).

**Früchte:**
- Sie liegen auf der Bahn der Kapselmitte (Füße + 1,0) eines gehaltenen Sprungs aus der Fenstermitte (Helfer `fruechte_bahn`).
- Über L3 zwei Höcker (1,86 bei 4,7 m und 2,15 bei 11,9 m, bei v 14,9).
- Am Horst die Bahn des Scheiteldrucks bis 4,2 m.
- Sichtweite wie in `level01.gd:845-857`.

### 6.5 Rastplätze (Zone 20 × 5 × 1,5 wie heute)

| CP | s | `tempo_start` | nächste Pflicht | Zeit bis dahin |
|---|---|---|---|---|
| 1 | 46 | 12,07 | Stummel C1 | 4,7 s |
| 2 | 87 | 12,98 | Stummel C1 | 1,20 s |
| 3 | 121,5 | 13,71 | L1 | 1,27 s |
| 4 | 153,3 | 14,34 | L3 (doppelt) | **1,50 s** |
| 5 | 214,7 | 15,0 | Ast 240 | 1,20 s |
| 6 | 292,5 | 15,0 | Splitterbalken | 1,22 s |
| 7 | 411 | 15,0 | Hochstummel 431 | 1,27 s |

- Jeder Rastplatz hat Boden bei s und s + 7 (`reiter.gd:584-597`).
- Er ruft `setze_checkpoint(s)` und `GameState.checkpoint_gesetzt.emit()` auf (E22) und zeigt weiter „Rastplatz“.
- Optik: Flatterband in `KISTE_CHECKPOINT` an Aststangen außerhalb der Bahn.
- Die Unverwundbarkeit (1,2 s) schützt **nicht** vor Lücken (`reiter.gd:317-321`). Deshalb gilt die Regel ≥ 1,2 s bzw. ≥ 1,5 s bis zum nächsten Pflichtfenster.

### 6.6 Richtzeit und Zeitmodus

- Ritt 2 → 469,8: **33,1 s** (Nachbau). `zielzeit()` = **32 s**. Heute käme 479/15·1,5 = 47,9 s heraus (`level_basis.gd:316-327`).
- 28 NORMAL ergeben 9 Zeitkisten (jede dritte, Folge 2/1/3, `level_basis.gd:31-33`), zusammen **18 s Frost**. Sie liegen bei 8,7 / 58 / 101,6 / 134,1 / 165 (Horst) / 229,5 / 271 / 328,1 / 368; die letzte 7 s vor dem Ziel.

| Stufe | Grenze | nötiger Frost |
|---|---|---|
| Saphir | 32,0 s | 1,1 s |
| Gold | 27,2 s | 5,9 s |
| Platin | 23,0 s | 10,1 s (56 % der Zeitkisten) |

- Ungeprüft: ab wann die Uhr gegenüber dem Losreiten zählt.

### 6.7 Rückfall ohne Zusage zu E3

- Tempo nach einem Tod 11 m/s (`reiter.gd:556`). Damit gibt es **keinen Pflicht-Doppelsprung**: L3 hätte bei 11,3 m/s nur 0,18 s.
- L3 wird eine Einzellücke ≤ 3,4 m. Alle Einzellücken ≤ 3,4 m (Tipp ≥ 0,20 s bei 11 m/s).
- Der Horst bleibt als einziges Doppelsprung-Angebot. Das Lernziel „Doppelsprung als Weitsprung“ fällt aus L04 heraus; das wird ausdrücklich dokumentiert.
- Mit `tempo_max` 19 fährt G bei 18,5–19 m/s; der Slalom dort ist dann ungeprüft.

---

## 7. Kamera und Kollision

### 7.1 Kameraplan (geschaltet nach `_reiter.strecke`)

| Zone | hoehe / abstand / vorlauf | Reiter-s (Blende → halten → zurück) | Dauer der Blenden | Zweck |
|---|---|---|---|---|
| Verfolger | 6,4 / 12,5 / 9,0 | Grundwert | – | A, C, E, F unten, G, H |
| tief | 3,0 / 10,0 / 9,0 | 40→54, bis 83, 83→97 | 1,17 / 1,08 s | Durchschlupf als Dach |
| Brücke | 7,6 / 12,5 / 10,0 | 153→168, bis 215, 215→231 | 1,05 / 1,07 s | Horst-Abstand, Blick in die Runse |
| erhöht | 11,0 / 9,0 / 8,0 | 376→392, bis 413, 413→429 | 1,07 / 1,07 s | eigene Spur, Neigung ≤ 30,2° |

- **Deckel:** Kamera-y ≤ 5,3 für Kamera-s 58–71 (X−8 … X+5).
- **Unter dem Kreuzstamm:**
  - Gerechnet höchstens 5,14 m, über alle Fälle: q −4,4/0/+4,4, Einfach- und Doppelsprünge bei s 46–90, zweiter Druck +12…+33 Bilder.
  - Der Deckel greift dabei nie.
  - Die Kamera ist unter der Achse, solange der Reiter bei s 76,4–79,1 ist. „tief“ hält bis 83.
- **Strecke:** Die Kamera liest `strecke_von = _reiter.strecke`. Sonst springt `get_closest_offset` an X um 341 m, das gälte als Rundenwechsel (`corridor_camera.gd:356, 382`).
- **`sicht_maske = 8`.** Sichtsperren gibt es in L04 keine.

### 7.2 Regeln

| Regel | Inhalt |
|---|---|
| KR1 Kamerabahn | Entlang der Kamera-Strecke s − abstand, im Bereich \|q\| ≤ 0,85·Grenze + 1,2 und y von Bahn + hoehe − 1,2 bis min(Bahn + hoehe + 3,5; Deckel + 0,7): kein sichtbares Netz. Folge: Im tiefen Abschnitt B steht in der Bahn nichts über 1,8 m; in D liegt der Horst unter der Brücken-Kamera (Abstand ≥ 1,97 m statt 0,82 m). |
| KR2 Blenden | ≥ 1 s, also ≥ v · 1 s; der Plan prüft das selbst (`blenden_pruefen`). |
| KR3 Ebenen | Bodenband auf Wert 16, nur über Boden und Rinde. Kisten auf Ebene 1 (unverändert). Stämme, Teller und Hindernis-Optik ohne Kollision. Hindernisse sind Area3D mit Maske 2, die nur `koerper is Reiter` treffen. |
| KR4 Kreuzung | Maske-2-Zonen der oberen Bahn liegen ≥ y 7,5 (CP7: 7,5–12,5), die der unteren ≤ y 4,0. Unten keine Feder und keine Gegner (Abprall). |
| KR5 Lücken | Zwischen Kurve + 3 und −4 m keine Kollision auf 1\|16. Lückenkante = Kappenende ±0,05. Splitter in \|q\| ≤ Grenze + 0,6 nur unter Bahn − 0,3; außerhalb bis Bahn + 0,4. |
| KR6 Steigung | Rampen ≤ 20 %; bergab ≤ 36 % außerhalb von Fall-Lücken. |
| KR7 Knicke | ≤ 20°, Drehrate ≤ 45°/s (J1 44°/s, L1 39°/s, L3 27°/s, L4 45°/s). |
| KR8 Grenzen | Boden 4,4, Rinde 0,5, R4 1,0, Trichter ≥ 12 m; Kappe eben bis Grenze + 0,3. |
| KR9 Rastplätze | §6.5 |
| KR10 Ziel | ≥ späteste Landung + 0,5 m |

### 7.3 Todeszonen

- **Keine.** `absturzzonen()` entfällt (`level04.gd:157`).
- Der Tod kommt nur über `boden_pruefer` (Lücken) und die Hindernis-Zonen. Die Sturzprobe entfällt im Ritt (`level_check.gd:430-432`).
- **Tod in der Luft:** Gegen den Eindruck eines unsichtbaren Bodens (Jury SK 15) hängt sich das Level an `gestorben` und zeigt eine Splitter- und Laubwolke an der Sterbestelle. Wie das wirkt, ist ungeprüft.

---

## 8. Bild

### 8.1 Bildregel

**Untergrund-Code:**
- Silbergraue Kappe: Rinde, springen.
- Erde mit Gras: lenken.
- Cremeweißer Bruch: Lücke oder Kante.
- Moospolster: bündiger Stoß.

**Lücken-Code (jede Pflichtlücke):**
- Cremefarbene Bruchfläche an beiden Enden, die Landeseite zur Kamera mit Ø ≥ 2,5 m.
- Darunter dunkel; seitlich kein Bodennebel näher als 20 m.
- Ein Fruchtbogen in Form der Flugbahn.
- Bis 50 m voraus verdeckt in |q| ≤ 6 nichts über Bahn + 1.

**Komposition:**
- Senkrechtes gibt es nur als Ruine (Hochstümpfe 8–22 m) und als Fichtenrand.
- Innen offen (Lichtung), außen zu (Reisig, Fichtenrand).
- Zwischen Himmel und Bahn liegt ≥ 15 % dunkler Rahmen. Die Bahn ist die hellste Bodenfläche.

**Hintergrund:**
- 8–12 liegende Riesen in West-Ost-Richtung (±25°), Kronen nach Osten.
- 6–10 Hochstümpfe, 1–2 stehende Überlebende.

### 8.2 Wahrzeichen (gerechnet, waagerecht, + = rechts)

| s | Wahrzeichen |
|---|---|
| 0–40 | Teller −27° … −41°, Kreuzstamm +11° … 0° |
| 46–99 | Kreuzstamm als Dach |
| 98–194 | Brückenstämme +27° … 0°, Sturmwand im Osten (C–E) |
| 270–407 | Kreuzstamm +42° … 0°, Teller mittig (−2° … −5°) |
| 407–469 | Teller mittig, wächst |

**Stämme:**

| Stamm | Ø | Lage |
|---|---|---|
| R1 Kreuzstamm | 3,0 | Stammbruch, Stumpf 9 m bei J3, Krone östlich auf Starkästen |
| R2 Rampenstamm | 3,0 | Wurzelhügel unten, Krone auf R3 |
| R3 Brückenstamm | 3,0 | 3 Stücke, Kronenbruch E1, Stück aus L3 in der Runse |
| R4 der Große | 5,0 → 4,0 | auf Astbeinen, Teller im Westen |
| R5 Auffahrt | 3,0 | Bruchstück, Reim auf E1 |

Takt der Tore: Kreuzstamm (B), Wurzelhügel (C), Moossattel J1 (D), Splitterkrone (E), Runse (F), Astgabel J3 (G), Spalt (H).

### 8.3 Licht, Himmel, Nebel, Farbe (`Level04.tscn`)

**Licht:**
- Sonne: Azimut 200° (SSW), Höhe 32°, Farbe (1,0 / 0,93 / 0,82), Energie 1,1, Schatten 2 Stufen bis 80 m.
- Dazu Himmelslicht blau 0,35, Gegenlicht 0,1, Bodenlicht warm 0,1, Bildrahmen 0,2 (Vorbild `Level01.tscn:94-119`).
- Umgebung (0,50 / 0,58 / 0,70) mit 0,5; ACES, Belichtung 1,0; Glow an.

**Nebel:** `fog_mode` 1 von 30 bis 190 m, Dichte 0,6, Farbe (0,62 / 0,72 / 0,84), `fog_sun_scatter` ≤ 0,1.

**Himmel:**
- `himmel.gdshader`: Zenit (0,16 / 0,36 / 0,70), Horizont (0,60 / 0,72 / 0,85), `wolken_menge` 0,58, `huegel_hoehe` 0,05, `wald_kante` 0,025.
- **Neu, additiv:** Sturmwand mit `sturm_staerke` (Vorgabe 0 = aus), `sturm_richtung` 80° und `sturm_farbe`. Statisch, ohne TIME (`himmel.gdshader:26-31`).

**Stimmungsregler nach s** (Licht / Nebel): A 1,0/1,0 · B 0,85/0,9 bei 60–72 · C 1,0 · D 1,15/0,7 · Kehre 0,95/1,1 · F 1,05 · G 1,0 → 0,9 auf den letzten 18 m · H Spalt mit Lichtschacht.

**Farbziele** (kontaktbogen):
- Helligkeit 85–115, kühl 15–30 %, warm 15–35 %.
- Weidenröschen ≤ 4 %, warme Akzente ≤ 8 %.
- Heute liegt L04 bei 167–184 / 24–28 % / 0–1 %.

**Silber, ungeprüft:**
- Die Borke wird heute mit `rc * borke_farbe` gerechnet (`riesenstamm.gd:1243`). Braune Textur bleibt damit braun.
- Neu sind die Uniforms `entsaettigen` und `aufhellen` (Vorgabe 0) in `BORKE_SHADER` und im Borkenzweig von `wegboden` (`:265`).
- Das erste Probebild gilt dem „Blech“-Eindruck (`wegboden.gdshader:262-263`).

### 8.4 Modelle

| Rolle | Modell | Quelle, Lizenz |
|---|---|---|
| Fichtenrand, Mischrand | PineTree_1/2/3/5, CommonTree_1/2 (im Repo) | Quaternius Ultimate Nature Pack, CC0 (`natur2/unp/LIZENZ_UltimateNaturePack.txt`) |
| Totholz silbern | CommonTree_Dead_1/2 (Repo), **CommonTree_Dead_3** (neu) | dasselbe Paket |
| Pionierbirken | **BirchTree_1, BirchTree_3** (neu); Rinde über `aufhellen` | dasselbe Paket |
| Steine im Teller und in Kuhlen | **Rock_1, Rock_3** (neu), Rock_Moss_2/5/6 | dasselbe Paket |
| Stumpf, Moosholz | TreeStump_Moss, WoodLog_Moss | dasselbe Paket |
| Prozedural | Stammbahn (neu), Wurzelteller (neu), `Riesenstamm.stumpf` und `brettwurzel_in`, `Kronenwolke`, `Farnwerk`, `Rasensaum`, `Bodenstreu` + **Weidenröschen** (neu), `Totholzzaun.stueck` (Reisig), `Findling` | eigener Code |

- Die neuen Modelle sind schon umgewandelt (`scratchpad/modelle/fbxprojekt/glb/`). Damit sind es 21 Modelle in `natur2`.
- Die CREDITS-Zeile (`assets/CREDITS.md:12`) zählt die Dateien einzeln auf und wird erweitert.
- **Rückfrage R2:** Modellbudget für den ganzen Raum 1. Für L02, L03 und L05 bleiben noch 4 Modelle.
- Kenney wird in L04 nicht mehr benutzt.

---

## 9. Technik

### 9.1 Module

- **`scenes/levels/level04.gd`:** neu, `class_name Level04 extends KorridorLevel`.
  - Daten (E4): `SEGMENTE`, `ABSCHNITTE` {von, bis, art boden|rinde|luecke, grenze, stamm}, `STAEMME` {achse, radius_a/b, kappe, s_von/bis}, `LUECKEN`, `HINDERNISSE`, `KISTEN`, `FRUECHTE`, `RASTPLAETZE` {s, tempo_start}, `KAMERA`, `STIMMUNG`.
  - Abfragen: `abschnitt_bei`, `grenze_bei`, `boden_da`, `breite_bei`, `boden_bei`, `tempo_bei`.
  - Haken: `_bauschritte`, `zielzeit` (32), `rittfaelle`, `ritt_fahrplan`, `pruefprofil` ({"wegmaske": true}).
- **`scenes/levels/level04/`** (Instanzen, keine `static var`):

| Datei | Inhalt |
|---|---|
| `verlauf.gd` | G3-Kurve aus `SEGMENTE`; Kreuzungsprüfung (Plan ≤ 0,5 m, Höhe ≥ 7 m) |
| `staemme.gd` | R1–R5, Stücke, Hindernis-Optik passgenau auf die Zone |
| `gelaende.gd` | Windwurf-Relief, Runse, Kuhlen; Bauspeicher-Schlüssel `l04_gelaende_voll\|handy` |
| `wald.gd` | Waldsetzer: Rand, Hintergrundholz, Hochstümpfe, Birken, Fernfassung |
| `streu.gd` | Farnbett, Rasen, Moos, Weidenröschen, Reisigwälle |
| `stimmung.gd` | Regler, Laub, Vögel, Flatterband, Sterbewolke |

### 9.2 Gemeinsame Bausteine

**Neu:**
- **`scripts/kameraplan.gd` (G1):** `setze(von, werte, blende_m)`, `decke(s_von, s_bis, y)`, `werte_bei`, `decke_bei`, `blenden_pruefen(tempo)`. L04 braucht davon `strecke_von`, `decke` und `sicht_maske`.
- **`scenes/props/stammbahn.gd`:** Kreis mit ebener Kappe ≤ 0,15 r, Verjüngung; Rippen und Rauschen in |q| ≤ Grenze + 0,5 aus, Oberkante ±0,05; Bruch- und Moosenden; Netz im Bauspeicher.
- **`scenes/props/wurzelteller.gd`:** Erdkuchen, Brettwurzeln, Steine, Spalt; `Bauspeicher.netz("wurzelteller", …)`.
- **`scenes/props/flatterband.gd`**, Weidenröschen als neue `Bodenstreu`-Art.
- **In `korridor_level.gd`:** `ritt_hindernis()`, `ritt_rastplatz()`, `sichtweiten_einrichten()` (Kopie von `level01.gd:838-857, 1136-1175` zum Einschalten), `fruechte_bahn()`.

**Aus L01 übernommen:**
- Sofern L02 und L03 sie noch nicht herausgelöst haben: `Wegdecke`, `GelaendeBau`, `Waldrahmen`, `Stimmungsregler` (Technikkarte 3.2).
- `wegboden` (Waldweg und `wurzelruecken`) als eigenes ShaderMaterial, **nicht** `L01Boden.stoff` (dessen Zwischenspeicher hängt nur an der Art, `boden.gd:44`).
- `GelaendeFeld` mit Abstand nur zu den Bodenstücken. An X liegt nur B in der Wegmaske (ungeprüft).

### 9.3 Additive Änderungen an geteilten Dateien (L01 und Hub bleiben pixelgleich)

| Datei | Änderung |
|---|---|
| `corridor_camera.gd` | `plan`, `strecke_von`, `@export sicht_maske := 1\|8` (`:334`), Deckel nach `:445` |
| `level_basis.gd:195-211`, `rundgang.gd` | `blicke_nach_plan`, zusätzlich ein Halt an jeder Blende |
| `riesenstamm.gd` | `bruch_farbe` (Vorgabe = heute, `:860-861`), öffentliches `bruchflaeche_in`, `entsaettigen`/`aufhellen` in `BORKE_SHADER` (`:1181ff`) |
| `wegboden.gdshader` | `entsaettigen`/`aufhellen`, helle Lippe `lippe_hell` = 0 |
| `himmel.gdshader` | Sturmwand mit `sturm_staerke` = 0 |
| `foto.gd:250-262` | setzt `strecke`, wo die Figur das Feld hat |
| `spieltest.gd:614-634` | `ritt_fahrplan()`, sonst die heutige 7-m-Regel (L06 und L17 bleiben gleich) |
| `pruefe.sh` | Rittprobe nach dem Muster `:111-118` |
| `schaufenster.sh:102` | Teil `l04` |

### 9.4 Reiter, Kamera, Floß, Keiler

- **`reiter.gd` und `Reiter.tscn` unverändert** (L17). `Level04.tscn`: `tempo_max` 15 (R1).
- Das Level setzt `verlauf`, `seiten_grenze = grenze_bei`, `boden_pruefer = boden_da`, `ziel_strecke` 469,8, `strecke` 2.
- **Neigung am Hang:** Katze und Modell werden im `_physics_process` des Levels um den Reiter-Ursprung mit `rotation.x` gedreht. Das Modell steht bei (0 | 1,18 | 0,12) und wird mitversetzt. Die Glattprobe muss sauber bleiben (ungeprüft).
- Floß (L03) und Keiler (L05): keine Änderung.

### 9.5 Bauschritte und Bauspeicher

Verlauf und Daten entstehen **vor** der Liste. Reihenfolge:

1. Riesen
2. Wurzelteller
3. Rinde und Bodenband
4. Gelände (frisch: vermessen, Hänge, Farbe; aus dem Speicher: ein Schritt)
5. Hindernisse
6. Kisten
7. Früchte
8. Rastplätze
9. Windbruch 1/4 … 4/4
10. Farne und Moos
11. Licht und Sichtweiten
12. Portale
13. Katze satteln (Plan, Tempo)

Ziele:
- Kein Schritt dauert warm länger als 150 ms.
- Aufbau warm ≤ 1124 ms, kalt ≤ 7,3 s (heute 3654 ms; `bauzeit_l04*.log`).
- Die Zellnetze des Waldes kommen in den Bauspeicher, falls der Wald warm über 300 ms liegt.

### 9.6 Handyweg (`Effekte.reduziert`)

- Waldsetzer: jedes zweite Stück, Birken nur nah, Kronenwolke nur fern.
- Streu halb; Laub und Vögel aus.
- Gelände-Abstand × 1,5 mit eigenem Schlüssel.
- Kisten 50 m, in F 40 m; Früchte 45 m.
- Schatten 1 Stufe, 50 m (`level_basis.gd:264-266`).
- **Katzenschatten aus** (`cast_shadow` der 37 Flächen setzt das Level, `katze.gd` bleibt unverändert). Ob dafür ein Bodenschatten aus `bodenschatten.gd` nötig ist, ist ungeprüft.

---

## 10. Leistungsbudget (Schätzung, ungeprüft; P3 misst den Rohbau zuerst)

| Posten | Rechner | Handy |
|---|---|---|
| Reiter und Katze (37 Flächen, gemessen) | 74 | 38 |
| HUD, Effekte | 25 | 25 |
| Himmel, Gelände, Decken | 12 | 10 |
| Stammbahnen und Teller (je Stamm verschmolzen) | 30 | 18 |
| Hintergrundholz | 24 | 14 |
| Wald (Waldsetzer, Fernfassung) | 45 | 30 |
| Birken | 10 | 4 |
| Reisig, Rasen, Streu, Farn | 45 | 30 |
| Stimmung | 12 | 6 |
| **fest** | **277** | **175** |
| Kisten (je 6 bzw. 5 Aufrufe, `level01.gd:840-841`) | Anzahl × 6 | Anzahl × 5 |
| Früchte | Anzahl × 1 | Anzahl × 1 |

**Kisten und Früchte im Bild (gerechnet):** Kisten mit Sichtweite 65 m am Rechner, 50 m am Handy (40 m in F); Früchte mit 58 bzw. 45 m.

| s | Kisten im Bild (Rechner / Handy) | Summe Rechner | Summe Handy |
|---|---|---|---|
| 10 | 9 / 6 | ≈ 342 | ≈ 213 |
| 75 (tief) | 9 / 5 | ≈ 344 | ≈ 210 |
| 165 (Horst) | 3 / 3 | ≈ 307 | ≈ 199 |
| 212 (bergab) | 10 / 8 | ≈ 351 | ≈ 224 |
| 330 | 7 / 6 | ≈ 330 | ≈ 214 |
| 400 (erhöht, +40/+25 für mehr Boden) | 11 / 11 | ≈ 404 | ≈ 273 |
| 445 | 0 / 0 | ≈ 283 | ≈ 181 |

- **Grenzen je Bild:** Rechner ≤ 480, Handy ≤ 440 (Rahmen 450), Primitive ≤ 750k, VRAM ≤ 128 MB.
- Heute liegt L04 bei 771 (Rechner) und 655 (Handy).
- **Sicherheitsabstand:** Die Handysumme ist vermutlich zu optimistisch, L01 misst dort 387–436. Gegenmittel in dieser Reihenfolge:
  1. Kistensicht in F 30 m.
  2. Fernwald × 0,6.
  3. Streu je Zelle zusammenlegen.

---

## 11. Risiken

1. **R1 wird abgelehnt.** Dann gilt §6.7: L3 ist keine Pflicht mehr, und das Lernziel fällt weg.
2. **Kurve in Godot gegen Plan.** Abweichungen bis ±0,5 m drücken die engsten Fenster (Tipp 0,217 s). Die Rittprobe misst auf der gebackenen Kurve; die Marken werden über `get_closest_offset` des Planpunkts umgerechnet.
3. **Silber wirkt als Blech** oder die Kappe als Bohlenweg. Gegenmittel: Probebild in P4 vor allem anderen, Kappe ≤ 0,15 r.
4. **Kanten bei 15 m/s lesen.** Gerechnet sind die Hindernisse 1,5 s vorher im Bild; wie gut man Kanten liest, ist ungeprüft. Gegenmittel: Lücken-Code und Fruchtbögen.
5. **Länge 479,2 von 480 m.** Kein Puffer. Jede Verlängerung kostet Kehre und Rückweg doppelt.
6. **Draw-Calls in F und auf dem Handy:** siehe §10.
7. **Neigung von Katze und Modell:** Glattprobe (Level 04 steht fest in `glattprobe.gd:57`).
8. **Bot:** Erst mit `ritt_fahrplan` fährt er durch. Ohne GPU nicht gelaufen.
9. **Modellbudget Raum 1** (R2).
10. **`cash_banooka_rc.glb` fehlt in CREDITS.** Das betrifft den ganzen Raum, nicht nur L04, und muss vor den Nachher-Bildern geklärt sein.
11. **Ungeprüft:**
    - die Figurhöhe 2,20 m im Sprung unter X (Abstand 0,54 m);
    - die Stimmung an der Kreuzung (deshalb ein Regler statt `stimmung()`-Zonen);
    - wie der Uhrstart im Zeitmodus zählt.

---

## 12. Arbeitspakete (Reihenfolge)

Jedes Paket endet mit `pruefe.sh` → `ERGEBNIS: SAUBER`. Gerendert wird nur gezielt.

**P0 Rückfragen** (vor P3):
- R1: Tempoverlauf (`tempo_max` 15, Rastplatz-Tempo).
- R2: Modellbudget Raum 1.
- R3: Verhältnis NORMAL/FRUCHT und `zielzeit` 32 s.

### P1 `kameraplan`, Teil von G1

- **Ziel:** §7.1 als gemeinsamer Baustein; L04-Felder `strecke_von`, `decke`, `sicht_maske`; Rundgang nach Plan; `foto` setzt `strecke`.
- **Dateien:** `scripts/kameraplan.gd`, `corridor_camera.gd`, `level_basis.gd`, `rundgang.gd`, `werkzeuge/foto.gd`.
- **Abnahme:**
  - Schaufenster l01, l01seite, l01nah und hub: `werte.tsv` und Bilder gleich.
  - Kamzonenprobe: Plan-Werte ohne Nahtausfall.
  - Rundgangprobe mit L04.

### P2 `rittprobe` (G5)

- **Ziel:** `werkzeuge/rittprobe.gd` und `.tscn` mit `rittfaelle()` {name, art luecke|doppel|huerde|lenken, s, ende/hoehe/tiefe/q}.
  - Je Fall: Tempo des Erstlaufs, gehalten und Tipp 6 Bilder, Doppelsprung mit Druckspanne.
  - Lagefälle: Kreuzung, KR4, Horst nur doppelt, Deckel gegen Unterkante, Blenden, Rastplatz-Zeiten, Ziel nach der Landung.
  - Dazu `ritt_fahrplan` im Spieltest und der Eintrag in `pruefe.sh`.
- **Abnahme:** Die Probe reproduziert alle Zahlen aus §6.2 und §6.5 auf ±0,02 s.

### P3 `rohbau`

- **Ziel:** `level04.gd` mit allen Tabellen; Kurve G3; Graubox-Stämme mit Kappe; Bodenband auf Wert 16; Zonen, Kisten, Früchte, Rastplätze mit `emit`; Tempo; `zielzeit`; ohne Absturzzonen, Pfosten, Bordstein, Horizont und `Baum.tscn`.
- **Abnahme:**
  - Rittprobe SAUBER, LevelCheck 46 Kisten ohne Fehler, Glattprobe 0.
  - Spieltest `TEST_LEVEL=04` bis ins Ziel.
  - Bauzeit gemessen.
  - **Draw-Calls und Primitive des Rohbaus** bei s 10, 75, 165, 212, 330, 400, 445, am Rechner und mit `FOTO_REDUZIERT=1`.
  - Kreuzung im Grundriss ≤ 0,5 m, Höhe 8,8.

### P4 `stammbahn`

- **Ziel:** Stammbahn, `bruch_farbe`, `entsaettigen`/`aufhellen`, Lücken-Code, Werkstatt-Station „Windbruch“ (Stammbahn mit Band begehbar, Teller, Zonen sichtbar; das Reitverhalten prüft die Rittprobe, dokumentierte Ausnahme).
- **Abnahme:**
  - Probebild Silber und Creme (seite 100, 185).
  - L01 und Hub pixelgleich.
  - Splitterregel KR5 per Probe.

### P5 `teller`

- **Ziel:** Wurzelteller mit Spalt, Lichtschacht, Kuhle mit Tümpel.
- **Abnahme:** Spalt ≥ 6 m unten und ≥ 4,7 m auf Kamerahöhe (Bahn + 6,4); Bild bei 445 und 469.

### P6 `gelaende`

- **Ziel:** Gelände mit Runse, Senke 308–328, Kuhlen; Wegdecke; Reisigwälle.
- **Abnahme:** Wegmaskenprobe; LevelCheck; Seitenbild bei 318.

### P7 `wald`

- **Ziel:** Import der 5 Modelle mit CREDITS und LIESMICH; Waldsetzer, Hintergrundholz in Sturmrichtung, Birken, Fernfassung.
- **Abnahme:** Draw-Calls je Station ≤ §10; VRAM ≤ 128 MB; Bauzeit warm ≤ 300 ms für den Wald.

### P8 `streu`

- **Ziel:** Farnbett, Rasen, Moos, Weidenröschen, Halme in B.
- **Abnahme:** Kistenabstand ≥ 1 m zum Gras; Handy-Werte.

### P9 `stimmung`

- **Ziel:** `Level04.tscn` (Licht, Himmel mit Sturmwand, Nebel, Bildrahmen), Regler, Flatterband, Laub, Vögel, Sterbewolke.
- **Abnahme:** kontaktbogen-Farbziele §8.3; Glattprobe; Bilder verfolger 10, 38, 75, 145, 165, 186, 206, 250, 318, 385, 400, 440, 469.

### P10 `leistung`

- **Ziel:** Handyweg, Sichtweiten, Bauspeicher.
- **Abnahme:**
  - Rechner ≤ 480 und Handy ≤ 440 an allen Stationen.
  - Primitive ≤ 750k.
  - Aufbau warm ≤ 1124 ms, Bauzeitprobe Runde 2.
  - Ruckelprobe `RUCKEL_LEVEL=…Level04.tscn RUCKEL_REDUZIERT=1`.

### P11 `doku`

- **Ziel:**
  - `doku/level04-neubau.md` (dieser Entwurf mit den Ist-Werten).
  - `doku/level-vorbilder.md` (Stammbahn, Wurzelteller, Reisigwall, Flatterband, Weidenröschen, `ritt_hindernis`, `ritt_rastplatz`, Kameraplan-Zonen, `fruechte_bahn`).
  - Schaufenster-Teil `l04`, CREDITS.
- **Abnahme:** Schaufenster mit VORHER=HEAD für l01 und hub: gleich; l04: neu.