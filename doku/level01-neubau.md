# Level 01 „Wurzelschlucht" – Neubau: Kammweg zum Weltenbaum

> **Stand:** Das ist der Entwurf, nach dem Level 01 neu gebaut wurde. In der
> Umsetzung haben sich einzelne Maße verschoben – etwa die Furtsteine
> (177,0 und 181,4 m), der Moosstamm als Pflichthürde über die ganze
> Wegbreite und das gemessene Budget (283–457 Draw-Calls am Desktop,
> 387–436 auf Handys). Maßgeblich sind die Daten in
> `scenes/levels/level01.gd` und die Kopfkommentare der Module.

Leitender Entwurf aus drei Konzepten (`panorama`, `waldboden`, `spielfluss`) und
zwei Jury-Urteilen. Rückgrat ist **panorama**. Übernommen sind die stärksten Ideen
der anderen beiden, und alle Fehler, die die Jury gefunden hat, sind behoben.
Grundlage ist der Repo-Stand `13dd0bd`. Er schließt die Physikinterpolation ein
(Regel „Bildtakt und Physiktakt“ in ARCHITEKTUR.md).

Alle Zahlen zu Kurve, Kamera und Sprüngen sind nachgerechnet. Das Rechenmodell
bildet `kurve_aus_punkten` (Bezier-Griffe ±(n−v)·glättung/2) und `KorridorKamera._folgen`
nach. Die Rechenskripte dazu lagen nur in der Bauumgebung und sind nicht
im Repo; nachprüfbar sind die Werte über `level_check.gd` und `Sprungprobe`.

---

## 0. Pitch

Level 01 hört auf, ein Schlauch zu sein, und wird eine Reise. Man beginnt in
einem dunklen **Hallenwald**. Nach 30 Metern tritt man auf einen **Hangweg** 20 m
über einem sonnigen Tal. Ab da hat man das Ziel ständig vor Augen: einen
**Weltenbaum** mit 24 m Stammdurchmesser auf der anderen Talseite, an seinem Fuß
die Lichtsäule des Zielportals. Durch die **Fallklamm** geht es an einem
zweistufigen Wasserfall vorbei hinunter. Dann über die **Bachwiese** zu Füßen des
Riesen, und auf einer Wurzel, die sich um seinen Stamm windet, hinauf bis unter
die Krone. Das letzte Bild blickt über das ganze Tal zurück auf Wasserfall und
Grat.

Eine einzige Bildregel trägt das Level: **Links ist zu, dunkel und nah**
(Hallenwald, Böschung, Felswand, Stamm). **Rechts ist offen, hell und weit**
(das Tal). Jedes Bild hat also einen dunklen Rahmen, einen hellen, ausgetretenen
Pfad und 150 m Tiefe im Dunst.

Rasen, Kanten und Modelle sind neu:
- Der Pfad tritt sich in echten Rasen ein. Es gibt keinen grünen Bordstein mehr.
- Grasnarben hängen über Felskanten, von denen Wurzeln baumeln.
- Die Felswände sind modelliert und tragen Schichten in Weltkoordinaten. Es gibt keine Würfelwände mehr.
- Der Wald besteht aus CC0-Stilmodellen und prozeduralen Riesenstämmen statt aus Blobs.

---

## 1. Entscheidungen (Synthese)

| # | Entscheidung | Herkunft | Warum |
|---|---|---|---|
| E1 | Aufbau Hallenwald → Hangweg → Fallklamm → Bachwiese → Wurzelwendel → Kronentor; Regel „links zu / rechts offen“; Weltenbaum als Wahrzeichen | panorama | beste Antwort auf „Tiefe“ und „Schlauch“ (beide Jurys) |
| E2 | Technik für Weg, Rasen und Kanten: `wegboden`-Shader mit Wegmaske, CPU-Maske = GPU-Maske, `Rasensaum`, Saum-Profile mit Grasnarbe, Weltschichten-Fels | panorama | behebt Bordstein und Würfelwände an der Wurzel |
| E3 | **Spirale mit R 22 m statt 16 m**, 8 m breit, außen ein **Rindenwulst** (0,6 m, Kollision) wo es tödlich wird, innen steiles Wurzelfleisch statt begehbarer Rampe | Jury 2 (a) | Die Sehnenkamera zeigt auf R 16 um 6,3° nach außen (0,93 m/s Drift zur Todesseite). Auf R 22 sind es 4,5° (0,66 m/s), und der Wulst fängt die Drift ab. |
| E4 | **Sprungregel für Level 01**: Pflichtsprünge sind Einzelsprünge über höchstens 3,0 m (flach) oder Stufen bis 1,0 m nach oben. Doppelsprung, Slide-Sprung, Feder und Sprungfeder gibt es nur in Geheimnissen. | spielfluss | Lehrlevel |
| E5 | **Sichere Enthüllung**: Von s 33 bis 50 steht am Rand ein Totholzgeländer mit Findlingen (Leitlinie dahinter). CP1 steht auf dem Aussichtsfels, der „Kanzel“ (s 44). Die offene Kante beginnt erst nach dem Checkpoint. | Jury 2 (2), spielfluss | Der Tod an der Enthüllung vor dem ersten CP war der Hauptmangel von panorama |
| E6 | **Lehre nach Angebot**: Kröte direkt nach einem Kistendreieck, Käfer unter einer Felsstufe, Spinne in der engen Torbaum-Pforte (s 101,5, statt s 166) | spielfluss | Die Antwort liegt jeweils auf der Hand. Alle drei Lektionen liegen in den ersten 105 m. |
| E7 | Mooslog 0,8 m quer über den Weg als Hüpflektion (s 8) | spielfluss | |
| E8 | **Regelbruch einmal**: Die geschlossene linke Seite öffnet sich einmal, zur **Moosbank** (s 83–91). Das Simsversteck über der offenen Kante entfällt. | Jury 1, Befund 2 aus level-vorbilder | Der Bruch lehrt nicht „vom Rand springen ist sicher“ |
| E9 | Fünf Geheimnisse, je eine Fortgeschrittenen-Bewegung (Feder, Doppelsprung, Slide-Sprung, Sprungfeder, Käfer-Abprall) | spielfluss, Jury 1 | Belohnungsvertrag |
| E10 | Keine Nitro in einer Drehschlag-Reihe; genau **eine** Nitro, frei stehend (s 168) | Jury 2 (b) | |
| E11 | Käfer-Abprall mit dem richtigen Wert: `abprall_hoehe` 14 ergibt 2,58 m, mit anschließendem Doppelsprung 4,03 m | Jury 1 (4) | panorama rechnete mit v16 |
| E12 | `Riesenstamm`, `Kronenwolke`, `Findling`, `Farnwerk` (prozedural) als Helden und als Modell-Rückfall statt Baum-Blobs | waldboden | Der Look hängt nicht am Netz |
| E13 | Findling-Regel: Jede begehbare Fläche außerhalb des Pfads ist ein Körper, dessen Optik genau zu seiner Kollision passt. CC0-Felsen sind nur Deko. | waldboden | |
| E14 | Kantenkatalog: Lippen von Lücken mit bündigen hellen Steinen und warmen Leuchtpilzen (keine Pfosten, kein Seil); Stamm- und Findlingsfüße 1 m versenkt, mit Verdeckungsring | waldboden | |
| E15 | Kronenlicht (Lichtflecken) als Weltrauschen im Bodenshader, auf dem Pfad halb so stark; **Kronen werfen keine Schatten**, nur Stämme | waldboden | Der Pfad bleibt das Hellste im Bild und ist billiger |
| E16 | Rahmenfarne und Rahmenzacken in den unteren Bildecken | waldboden, level-vorbilder („Rahmenzacken“ offen) | |
| E17 | **Neue Kollisionsebene 5 (Wert 16) „Spielergrenze“**: Leitlinien, Randkörper, erhöhte Begehbares. Die Figur stößt daran an, der Kamerastrahl (1\|8) nicht. | eigene Rechnung (Abschnitt 11) | Der Strahl startet 6 m **vor** der Figur. Ein Hindernis zwischen Blickpunkt und Figur (einrückende Leitwand, Pfortenkörper, Nischenende) zöge die Kamera **vor** die Figur. |
| E18 | Keine schwebenden Kisten in Level 01 | eigene Rechnung | Kisten liegen auf Ebene 1 und stünden im Sichtschlauch |
| E19 | Level-Check-Proben (Sicht, Gefälle, Todeszonen-Überschneidung), **nur per Opt-in** | beide Jurys | `pruefe.sh` prüft alle 25 Level |
| E20 | Die Sonne bleibt (68°, SSO). Die Lichtfolge entsteht aus dem Kurs: Kurs N ist Frontlicht, NO/O Seitenlicht, W/SW am Ziel Gegenlicht. | spielfluss (Lichtfolge) | `splash_kulisse.gd` und die Lichtschächte bleiben unberührt |
| E21 | Name bleibt „Wurzelschlucht“: Die Fallklamm ist die Schlucht | panorama | kein Eingriff in Hub oder Spielfluss |

Verworfen:
- der 5-m-Pflicht-Doppelsprung (panorama G2) und die schwebende Kiste über G2;
- die Stammbrücke, die Stacheln und die Pflicht-Doppelsprünge aus waldboden;
- der Waldboden-Heightfield-Streifen als Ersatz für `korridor` (panorama behält `korridor`: Hilfen und Proben bleiben gültig);
- die 12-%-Grenze für Anstiege: Sie ist zu streng. Hier gelten 20 % (Abschnitt 11).

---

## 2. Feste Größen und Rechenwerte

**Physik (unverändert, CLAUDE.md):** G −38, JUMP_V 12,2, DJUMP_V 10,5, RUN 8,5, AIR_CTRL 0,82,
SLIDE 13,5 / 0,42 s, SLIDEJUMP_V 14,5, SLAM −30, SPIN 0,55 s mit Reichweite 1,7 m.

| Größe | Wert | Herleitung |
|---|---|---|
| Luftgeschwindigkeit | 6,97 m/s | 8,5 · 0,82 |
| Sprung | Scheitel 1,96 m, 0,64 s, **4,47 m** flach | 12,2²/76 |
| Sprung auf +h / −h | Weite 6,97 · (0,321 + √(2(1,958 ∓ h)/38)) | +0,5 m → 4,16 m · −0,76 m → 4,87 m |
| Doppelsprung | +1,45 m → Scheitel **3,41 m**, rund 7 m weit | 10,5²/76 |
| Slide-Sprung | Scheitel **2,77 m**, 5,3 m weit | 14,5²/76 |
| Federkiste | 2,96 m über der Kistenoberkante (3,96 über dem Boden) | 15²/76 |
| Sprungfeder | 5,26 m über der Kistenoberkante (**6,26** über dem Boden) | 20²/76 |
| Gegner-Abprall | **2,58 m**; der Doppelsprung ist danach wieder frei → **4,03 m** | `abprall_hoehe` 14; `abprallen()` setzt `can_djump` |
| Drehschlag | Kistenmitte < 1,7 m von Füßen + 0,5 m; der Doppelsprung dreht 0,2 s mit | `_spin_treffer` |
| Kisten | brechen durch Drehschlag, Slide, Bauchplatscher und Fall von oben, **nicht von unten** | `kiste.gd` |

**Kamera (unverändert, `corridor_camera.gd`):**
- Höhe 6 m, 9,5 m zurück **auf der Kurve**.
- Blickpunkt 6 m voraus auf Figurhöhe +1 m; seitlich folgt sie zu 0,85.
- Sichtfeld 60° senkrecht (91,5° waagerecht bei 16:9), `far` 200.
- Neigung in der Ebene ≈ 18°: Der obere Bildrand liegt bei +12°, der Horizont ≈ 22 % unter dem oberen Rand.
- Bergab mit 30 % steht die Kamera 2,9 m höher und neigt ≈ 26°. Bergauf mit 17 % steht sie 1,6 m tiefer und neigt ≈ 14°.
- Sichtstrahl: vom **Blickpunkt** zur Kamera, Ebenen 1|8. Treffer näher als 1,4 m zählen nicht; ein Strahl, der in einem Körper beginnt, trifft ihn nicht.

**Renderer:** gl_compatibility (WebGL2, Handy). Zwei Schattenstufen, 70 m (Web 60 m).
Physikinterpolation ist an: Was im `_process` bewegt wird, bekommt
`PHYSICS_INTERPOLATION_MODE_OFF`. Wind im Vertexshader bewegt keine Knoten und
braucht das nicht.

---

## 3. Verlauf

`LevelWerkzeuge.kurve_aus_punkten(PUNKTE, 0.34)`. Mit 0.45 schießen die Griffe
über, und die Spirale eiert. **Länge 287,0 m.** Die Richtzeit wird abgeleitet:
287 / 8,5 · 2,8 = **94,5 s**, ohne Überschreiben.

```
PUNKTE = [
 (0,26,4), (0,26,-14), (1,26,-30), (4,25.5,-48), (9,24.5,-65), (15,23.5,-81), (21,22.6,-95),    # A, B
 (27,21.3,-106), (33.5,18.6,-115.5), (40.5,15.2,-123.5), (48.5,11.6,-130.2), (57,9.0,-135.6),   # C
 (65.5,7.6,-140.8), (74,7.1,-146.3), (81.5,7.1,-152.4),                                         # D
 (87.58,7.6,-158.48), (92.23,9.04,-165.32), (94.02,10.49,-173.4), (92.7,11.93,-181.56),         # E: Spirale
 (88.46,13.38,-188.66), (81.9,14.82,-193.7), (73.94,16.27,-195.95), (65.72,17.71,-195.11),      #    um Achse (72.0, -174.0)
 (58.38,19.16,-191.29), (52.97,20.6,-185.04),                                                   #    R 22, θ 45°→240°, Schritt 21,67°
 (49.97,21.0,-179.84), (46.47,21.0,-173.78) ]                                                   # F: Regal, Kurs -150°
```

Weltenbaum: Achse **(72,0 | –174,0)**, Stammradius 12 m am Fuß, 8 m unter der Krone.
Die Krone ist ein Schirm mit Radius 34 m. Ihre Unterseite liegt am Rand auf y 32
und am Stamm auf y 40, die Oberseite auf y 72, die Mitte bei y ≈ 54.

| s | Welt (x, y, z) | Kurs | Steigung | Radius |
|---|---|---|---|---|
| 0 | 0,0 · 26,00 · 4,0 | 0° | 0 % | gerade |
| 33 | 0,9 · 26,01 · −29,0 | 6° | −1 % | 150 (rechts) |
| 56 | 4,9 · 25,33 · −51,6 | 15° | −5 % | 125 |
| 66 | 7,7 · 24,74 · −61,2 | 18° | −6 % | 325 |
| 92 | 16,8 · 23,23 · −85,5 | 22° | −5 % | 335 |
| 104 | 21,7 · 22,48 · −96,4 | 26° | −8 % | 123 |
| 118 | 28,5 · 20,76 · −108,5 | 33° | −20 % | 115 |
| 133 | 37,2 · 16,81 · −120,0 | 41° | −31 % | 75 |
| 145 | 45,4 · 12,89 · −127,8 | 51° | −33 % | 83 |
| 160 | 57,4 · 8,91 · −135,9 | 58° | −19 % | gerade |
| 173 | 68,4 · 7,34 · −142,6 | 58° | −6 % | 390 (links) |
| 183 | 76,6 · 7,04 · −148,3 | 52° | −1 % | 87 (links) |
| 198 | 87,6 · 7,60 · −158,5 | 40° | +12 % | 52 (links) |
| 210,5–273 | Spirale | 13° → −144° | **+17 %** | 22 (links) |
| 283 | 48,5 · 21,03 · −177,2 | −150° | 0 % | gerade |
| 287 | 46,5 · 21,00 · −173,8 | −150° | 0 % | Ende |

Kurs 0° = Norden (−Z), +90° = Osten (+X). Die Kurven außerhalb der Spirale haben
Radius ≥ 52 m, auf dem Grat ≥ 120 m. Keine Kehren.

---

## 4. Abschnittstabelle

`ABSCHNITTE` ist wie bisher die einzige Quelle für Breite und Lücken. Neu ist
`"hoehe"`/`"hoehe_ende"`: die absolute Welt-Y der Wegdecke, linear gemischt.

| Eintrag | von–bis | Breite | Oberfläche (Welt-Y) | Anmerkung |
|---|---|---|---|---|
| A1 | 0,0–25,0 | 10 | Kurve (26,0) | Hallenwald |
| Erdspalt | 25,0–27,5 | – | – | 2,5 m flach |
| A2 | 27,5–33,0 | 10 | Kurve | Enthüllung |
| B1 | 33,0–56,0 | 9,5 | Kurve (26,0 → 25,3) | Geländer, Kanzel |
| Kerbe | 56,0–59,0 | – | – | 3,0 m, −0,17 m |
| B2 | 59,0–66,0 | 9,0 | Kurve | |
| B3 | 66,0–80,0 | 9,0 | **23,90 → 23,92** | Felsstufe 0,84 m ab bei 66 |
| B4 | 80,0–92,0 | 9,0 → 7,5 | Kurve | Moosbank-Nische links |
| B5 | 92,0–104,0 | 7,5 | Kurve (23,2 → 22,5) | Felsnase, Torbaum-Pforte |
| C1 | 104,0–118,0 | 7,5 | Kurve (22,5 → 20,8) | Kuppe gerundet (−8 → −20 %) |
| Fallkerbe | 118,0–121,0 | – | – | 3,0 m, −0,76 m |
| C2 | 121,0–133,0 | 7,5 | **20,00 → 18,00** | Abstand zur Kurve −0,1 … +1,2 |
| C3 | 133,0–145,0 | 8,0 | **16,40 → 13,80** | Stufe 1,6 m ab bei 133 |
| C4 | 145,0–160,0 | 8,5 → 12 | **12,40 → 8,91** | Stufe 1,4 m ab bei 145 |
| D1 | 160,0–173,0 | 12 | Kurve (8,9 → 7,3) | Bachwiese, Wurzeltor 162 |
| Furt | 173,0–183,0 | – | Wasser y 6,0, tödlich | zwei Trittsteine |
| D2 | 183,0–194,0 | 12 | Kurve (7,0 → 7,2) | zwei Geheimnisse bei 188–193, bündig an der Kante ±6 |
| D3 | 194,0–198,0 | 12 → 8 | Kurve (7,2 → 7,6) | Übergang zur Wurzel |
| E1 | 198,0–210,5 | 8 | Kurve (7,6 → 9,7) | über der Wurzelwiese |
| G1 | 210,5–213,5 | – | – | 3,0 m, +0,51 m, **nicht tödlich** |
| E2 | 213,5–243,0 | 8 | Kurve (10,3 → 15,3) | Rindenwulst außen ab 214 |
| G2 | 243,0–245,5 | – | – | 2,5 m, +0,42 m, tödlich |
| E3 | 245,5–273,0 | 8 | Kurve (15,7 → 20,5) | Oberwurzel innen |
| F1 | 273,0–287,0 | 8 → 12 | Kurve (20,5 → 21,0) | Kronentor, Portal bei 283 |

| Abschnitt | links (zu) | rechts (offen) | Stimmung |
|---|---|---|---|
| A Waldsaum 0–33 | Hallenwald | Hallenwald, ab 26 Öffnung | kühl, gedämpft grün |
| B Hangweg 33–104 | Moosböschung + Hangwald | Felskante 18–20 m tief, Tal | golden, klar, kühle Ferne |
| C Fallklamm 104–160 | wachsende Schichtfelswand 2 → 14 m | Abbruch 20 → 3 m, Bach | kühl, Gischt |
| D Bachwiese 160–198 | Brettwurzeln des Weltenbaums | Blütenhecke, drei Talriesen | warm grün |
| E Wurzelwendel 198–273 | Wurzelfleisch und Stamm | Wurzelwiese, dann Wurzelgruben | golden |
| F Kronentor 273–287 | Stamm | das ganze Tal im Gegenlicht | golden |

---

## 5. Die Abschnitte im Einzelnen

### A · Waldsaum (0–33) – der Hallenwald

**Aufbau:**
- Ebenes Plateau auf y 26, Kurs 0 → 6°, begehbar 10 m.
- Leitlinien bei ±5,6 m (Ebene 16), verdeckt hinter Farnen, Mooslogs und Findlingen.
- Drei Stammreihen gerader, hoher Bäume (12–18 m): Reihe 1 bei |q| 7–10, Reihe 2 bei 12–16, Reihe 3 bei 18–24.
- Über |q| < 6 schließen die Kronen erst ab **9,5 m über dem Weg** zum Blätterdach.
- Zwei Lichtlöcher im Dach: s 14 bei q +3,5 und s 22 bei q −3,0.
- Hinter dem Startportal (s −8…0) ein Wurzelnest mit Querleitlinie. Die Heranhol-Kamera (s < 9,5) sieht Boden und Stämme, keine Leere.
- Wurzeltor bei s 3 zwischen zwei Stämmen der Reihe 1 (Scheitel 9,2 m).
- Der **Erdspalt** (25,0–27,5): ein wurzelgesäumter dunkler Riss, sichtbar ≥ 8 m tief. Er läuft je Seite 5 m über die Leitlinien hinaus in den Waldboden und wird dabei schmaler.
- Ab s 26 enden die Stämme rechts. Den Rahmen der Enthüllung bilden ein toter Baum (s 28, q +7) und ein bemooster Findling (s 31, q +6,5).

**Bild:**
- Dunkle Stammsäulen links und rechts, das Blätterdach als dunkles oberes Band, der helle Pfad; am Ende eine helle Öffnung.
- Ab s 24 stehen der Wasserfall (x +0,18, y +0,50) und der Weltenbaum (Stamm x +0,39) in der Öffnung.
- Bei s 31 die volle Enthüllung: Tal 20 m tief rechts, Wasserfall 96 m voraus, Krone des Weltenbaums im oberen Band (x +0,39, Unterseite y +0,60, 172 m).

**Spiel:**
- s 5–7 Fruchtreihe (4).
- s 8 **Mooslog** Ø 0,8 m quer (q −4,4…+4,4, Kapsel, Ebene 16): Hüpflektion.
- s 12 **Kistendreieck** NORMAL (q −1,0), NORMAL (+1,0), dahinter s 13,4 NORMAL (0). Ein Drehschlag im Lauf bricht alle drei.
- s 15,5 FRUCHT_MEHRFACH (q −2,5).
- s 18 **Sumpfkröte**, quer, Weite 3,5 (Drehschlag-Lektion).
- s 21 Stapel NORMAL (q −2,8) mit NORMAL obenauf (h 1,5), dazu NORMAL (+1,0) und SCHUTZ (+2,6).
- 24–28,5 Fruchtbogen über den Erdspalt, Scheitel 2,2 m.
- s 30,5 NORMAL (q −2,0).

### B · Hangweg (33–104) – der Grat über dem Tal

**Aufbau:**
- Kurs 6 → 26°, Oberfläche 26,0 → 22,5 (−1 … −8 %), Rechtsbogen R 120–335.
- **Links (zu):** Moosböschung ab q −5,0, 45–60° steil, auf +4…6 m bei q −10…−12. Dann Hangwald bis y ≈ 40.
  - Aus der Böschung kriechen Wurzeln; Findlinge und Farne sitzen darin.
  - Äste reichen ab 9,5 m über das linke Wegdrittel.
  - Leitlinie −5,3.
- **Rechts (offen):**
  - Grasschulter, dann eine unregelmäßige Grasnarbe am Rand (Lippe = Kollisionskante).
  - Darunter eine modellierte Schichtfelswand, 18–20 m tief, mit Simsen bis auf den Schutthang (y ≈ 6). Auf den Simsen stehen Rahmenbäume bei s 50, 76 und 98.
  - Die Talkronen liegen auf y 12–17, also **8–12 m unter dem Weg**; nichts davon sieht begehbar aus.
- **s 33–50 Totholzgeländer:** Spaltzaun aus Totholz mit Findlingen am Rand, dahinter die Leitlinie +5,2.
- **Kanzel (Aussichtsfels) s 40–48:** Findling-Platte, bündig mit dem Weg, q +4,75…+9,5, Ebene 1. Darauf eine Drehkiefer. Das Geländer läuft um die Platte (Leitlinie auf +9,8).
- s 50: Das Geländer endet an einem geborstenen Pfosten. Ab hier ist die Kante offen.
- **Kerbe 56–59:** eine Seitenrinne von der Böschung bis zur Felskante. Ein Rinnsal fällt hinein; unten ist es dunkel.
- **Felsstufe bei s 66** (0,84 m ab); B3 läuft eben weiter, bis die Kurve sie bei s 80 wieder einholt.
- **Moosbank-Nische s 78–98 (Regelbruch):**
  - Der Böschungsfuß weicht bis q −11 zurück.
  - Nischenboden bündig mit dem Weg (Ebene 1), Leitlinie als Polylinie: (78|−5,3) (82|−9,5) (84|−11,0) (92|−11,0) (95|−8,0) (98|−5,3).
  - Die Moosbank ist ein Findling-Sims s 83–91, q −6,5…−10,0, Oberkante **+2,6 m** (Ebene 16).
- **Felsnase 92–104:** Die Böschung wird zu grauem Felsausbiss (3–5 m), rechts wächst der Abbruch. Breite 7,5.
- **Torbaum-Pforte s 99,5–103,5:**
  - Zwei Körper auf Ebene 16, je 2,6 m hoch: links Fels (q −3,75…−2,2), rechts eine Brettwurzel des Torbaums (+2,2…+3,75). Öffnung 4,4 m.
  - Wurzeltor darüber, Scheitel 9,2 m (`Schluchtsaum.wurzeltor`, abstand 4,4).
  - Der Torbaum ist eine große Kiefer am Rand (q +6…+8, 22 m hoch).
  - Die Kurve ist dort nahezu gerade (R > 120).

**Bild:**
- Links dunkle Böschung und Wald, rechts 150 m Tal.
- Der Weltenbaum steht bei x +0,33 → +0,13, die Kronenunterseite bei y +0,63…+0,77 (oberes Band), der Stamm als Säule.
- Der Wasserfall bewegt sich von x +0,10 (s 44) nach −0,28 (s 104).
- Vögel kreisen **unter** Augenhöhe (Welt-y 16–20; die Kamera steht auf ≈ 31).
- Die Lichtsäule des Ziels steht als Leuchtfeuer am Fuß des Baums (x +0,06…+0,22, y +0,6).

**Spiel:**
- s 36–40 Fruchtreihe.
- s 44 **CHECKPOINT 1** (q +6,0, auf der Kanzel).
- s 46,5 NORMAL (+7,5) und FRUCHT_MEHRFACH (+8,6) auf der Kanzel.
- s 52 NORMAL (−1,5), NORMAL (0).
- Kerbe 56–59: Einzelsprung 3,0 m, landet 0,17 m tiefer (Weite 4,57, Reserve 1,57). Fruchtbogen.
- s 69,5 **Panzerkäfer** längs, Weite 1,25 (68,25–70,75), direkt unter der Felsstufe: Man springt von der Stufe auf ihn (Draufspring-Lektion).
- s 75 NORMAL (−1,2), NORMAL (+1,2).
- s 80,5 **FEDER** (q −3,4): Weg auf die Moosbank (**Geheimnis S1**; Feder 3,96 m oder Doppelsprung 3,41 m gegen 2,6 m).
- Moosbank: NORMAL (s 85, q −7,5), NORMAL (s 86,5, q −8,0), FRUCHT_MEHRFACH (s 88,5, q −8,5), jeweils auf der Simsoberkante.
- s 96 Stapel NORMAL (q −2,8) mit NORMAL obenauf.
- s 97–101 Früchte **am Boden** in die Pforte hinein (weist auf den Slide).
- s 101,5 **Stelzenspinne** quer, Weite 1,0 (Slide-Lektion). Umgehen ist unmöglich; drüberspringen ist riskant.

### C · Fallklamm (104–160) – am Wasserfall hinab

**Aufbau:**
- Kurs 26 → 58°, Rechtsbogen R 75–125. Die Kurve fällt 22,5 → 8,9 (bis −33 %).
- Die Wegdecke fällt in **Terrassen** mit absoluter Höhe (Tabelle 4). Ihr Abstand zur Kurve bleibt ≤ 1,2 m, die Kamera fährt die glatte Kurve.
- **Links:** Schichtfelswand, die von 2 m (s 104) auf ≈ 14 m (s 150) wächst.
  - Simse mit Farnen und Großblättern, hängende Wurzeln.
  - Die Oberkante kragt 1–2 m vor, aber nur ≥ 10 m über dem Weg.
  - Bei s 112–122 steht ein Wasserfallpfeiler (+11 m).
  - Leitlinie −4,6 (C1/C2), −4,9 (C3), −5,1 (C4).
- **Rechts:** offen, der Abbruch schrumpft von 20 m auf 3 m. Ab s 145 läuft der Bach am Fuß von C4 (tödliches Wasser).
- **Wurzelfall, zweistufig:**
  - Der obere Fall stürzt vom Pfeiler (y ≈ 31,5) links in ein Felsbecken (q −6…−9, y ≈ 19,5).
  - Das Wasser schießt unter der Fallkerbe hindurch (Bett y ≈ 18).
  - Der untere Fall stürzt die rechte Wand 13 m hinab in den Tümpel (Welt ≈ 41,7 | 5 | −103).
- Die Talbäume wachsen dem Spieler entgegen: Bis s 140 liegen ihre Kronen unter ihm, ab 145 flankieren sie auf Augenhöhe, und über C4 schließt sich das Dach (s 148–160). Man steigt **in** den Wald hinab.

**Bild:**
- Die Kamera steht 2–3 m höher und neigt ≈ 26°. Terrassen, Stufen und Kerbe lesen sich klar.
- Der Weltenbaum wandert nach links (Stamm x −0,03 → −0,39), die Krone verlässt das Bild nach oben. Über C4 verschwindet er hinter dem Walddach; ab s 160 ist er links wieder da.

**Spiel:**
- s 107 **CHECKPOINT 2** (0).
- s 108–112 Fruchtreihe.
- s 111 NORMAL (+1,5).
- **Fallkerbe 118–121:** 3,0 m, landet 0,76 m tiefer (Weite 4,87, Reserve 1,87). Fruchtbogen mit Scheitel 2,3 m. Unten rauscht das Wasser.
- s 124 NORMAL (0), NORMAL (+1,2).
- **TNT-Kette** an der Wand:
  - TNT (s 127,7, q −2,3);
  - NORMAL (126,5 | −2,3), NORMAL (128,9 | −2,3), NORMAL (127,7 | −1,1).
- s 133: Stufe 1,6 m ab (zurück hinauf reicht der Einzelsprung, 1,96 m).
- s 137 FRUCHT_MEHRFACH (q −2,0).
- s 140 **Panzerkäfer** quer, Weite 2,5.
- s 145: Stufe 1,4 m ab.
- s 148–157 Fruchtreihe die Rampe hinab.
- s 154 NORMAL (+2,0).

### D · Bachwiese (160–198) – zu Füßen des Riesen

**Aufbau:**
- Talboden, Kurs 58 → 40°, Weghöhe 8,9 → 7,0 → 7,6, begehbar 12 m, am Ende 8 m.
- Einfahrt durch ein Wurzeltor bei s 162 zwischen zwei Talriesen (q ±9, Scheitel 10 m).
- Der Pfad ist eine ausgetretene Erdspur, die innerhalb der Wiese ±2 m pendelt (Wegmaske).
- **Furt 173–183:** 10 m tödliches Wasser (Oberfläche y 6,0). Zwei flache Trittsteine Ø 2,6 m, Oberkante bündig (7,2):
  - s 175,9 bei q −1,0 und s 180,1 bei q +0,8;
  - Lücken 1,77 / 1,97 / 1,71 m;
  - Schaumringe um die Steine.
- **Links:** Knoll des Weltenbaums, dessen Brettwurzeln wie Wände steigen (Optik). Leitlinie −6,8.
- **Rechts:** Blütenhecke bei +7…+9 mit der Leitlinie +6,8. Drei Talriesen (32–38 m, Stamm Ø 3–4 m) stehen bei q +10…+14 auf s 166, 184 und 198; ihre Kronen decken die rechte Hälfte.
- **Geheimnisse S2 und S3:**
  - Der **Findlingsturm** (S2): s 188,5–191, q +6,0…+7,6, Oberkante **+3,0**.
  - Das **Wurzelknie** (S3): s 190–193, q −6,0…−7,6, Oberkante **+2,4**.
  - Beide liegen bündig **außen** an der Wegkante; die Leitlinie weicht dahinter auf ±7,8 aus.

**Bild:**
- Rasen in voller Sonne, der Bach glitzert, Stammschatten der Riesen liegen schräg über der Wiese (Seitenlicht).
- Voraus links der Stammfuß des Weltenbaums (x −0,63 → −0,95, Stamm 36–49 m entfernt) mit Brettwurzeln; die Krone ist aus dem Bild, nur die untersten Äste schneiden oben links hinein.
- Der Wurzelaufgang liegt voraus.

**Spiel:**
- s 166 **CHECKPOINT 3** (0).
- s 168 **NITRO** allein (q −3,4), dahinter NORMAL (s 169,2, q −3,4); die Kiste holt man mit Draufspringen oder über Eck.
- s 163–169 Früchte am Boden in Slide-Richtung.
- s 170 **Stelzenspinne** quer, Weite 2,0, um q +1,0 (Slide auf offener Fläche).
- s 171 NORMAL (+3,0), NORMAL (+4,2).
- Furt: auf jedem Stein 3 Früchte; Hüpfer im Takt.
- s 184,5 Reihe NORMAL (−1,6), FRUCHT_MEHRFACH (0), NORMAL (+1,6), ohne Nitro.
- **S2** Findlingsturm: nur mit Doppelsprung (3,41 gegen 3,0; der Slide-Sprung mit 2,77 reicht nicht). Darauf NORMAL (s 189,2 und 190,4, q +6,8).
- **S3** Wurzelknie: Slide-Sprung (2,77 gegen 2,4) oder Doppelsprung. Darauf NORMAL (s 191,5, q −6,8) und 3 Früchte.
- s 194,5 **Sumpfkröte** quer, Weite 2,5.
- s 196,5 Stapel NORMAL (q +2,6) mit NORMAL obenauf.

### E · Wurzelwendel (198–273) – auf den Riesen hinauf

**Aufbau:**
- Der Weg ist die **Kehle** zwischen der Hauptwurzel (innen, links) und einem zweiten Wurzelstrang (außen, rechts). Beide winden sich gegen den Uhrzeigersinn um den Stamm.
- Kreis R 22, Kurs 40° → −144°, y 7,6 → 20,5, konstant **17 %**, begehbar 8 m.
- **Innen:** steiles Wurzelfleisch (Kollision Ebene 16, ≥ 55°, nicht begehbar), Profil (q −4,0 | 0) → (−7,0 | +4,5) → (−10,0 | +9) bis zur Stammwand (r 12).
  - Die Stammwand trägt Borkenrippen, Moosstreifen, Konsolenpilze und Leuchtpilze in den Rissen und läuft oben aus dem Bild.
  - Keine Leitlinie innen.
- **Außen:**
  - s 196–214: die **Wurzelwiese**, ein begehbarer Rasenfleck auf y 7,0 (Ebene 1). Sie ist von einer Hecke begrenzt (Leitlinie auf r ≈ 34) und hängt bei s 196–200 am Weg. Ein Sturz dort kostet nur den Rückweg.
  - Ab s 214 der **Rindenwulst** (0,6 m hoch, Ebene 16) über dem Abgrund in die dunklen **Wurzelgruben** (Boden y ≈ −2, Todeszone knapp darin).
  - Der Wulst fängt die Kameradrift (0,66 m/s nach außen) ab.
- **G1 210,5–213,5:** ein Wurzelbruch über der Wurzelwiese. Unten ist Wiesenboden auf 7,0; der Weg zurück führt über die Wiese.
- **G2 243,0–245,5:** ein Wurzelbruch über der Grube, tödlich.
- **Oberwurzel s 250–263:** eine Luftwurzel am Stamm entlang (Ebene 16), q −5,4…−7,6. Ihre Oberkante steigt relativ zum Weg von +3,6 (s 250) auf +5,2 (s 263). Unterkante ≥ +3,0.
- Ab s ≈ 250 sieht man zum ersten Mal zurück zu Grat und Wasserfall (x −0,98 → −0,43).

**Bild:**
- Links füllt der Stamm das linke Fünftel (Silhouette bei x ≈ −0,6), darunter das Wurzelfleisch.
- Rechts schwenkt der Blick von der Wiese (O) über das Talkronendach (N) zu Grat und Wasserfall (W).
- Oben links Kronenäste mit Lichtflecken. Vögel kreisen jetzt auf Augenhöhe.

**Spiel:**
- s 202 NORMAL (−1,5), NORMAL (0).
- s 205–209 Früchte.
- **G1**: 3,0 m, +0,51 m (Weite 4,16, Reserve 1,16). Fruchtbogen.
- s 216–220 Früchte.
- s 222 **Sumpfkröte** quer, Weite 2,0.
- s 226 NORMAL (−1,2).
- s 232 **CHECKPOINT 4** (0).
- s 236 NORMAL (+1,5), FRUCHT_MEHRFACH (−1,5).
- **G2**: 2,5 m, +0,42 m (Weite 4,22, Reserve 1,72). Fruchtbogen mit Scheitel 2,3 m.
- s 249 **Panzerkäfer** längs, Weite 1,25, q −1,5. Er ist zugleich Trampolin: Abprall plus Doppelsprung (4,03) trägt auf das niedrige Ende der Oberwurzel (+3,6). Das ist **Geheimnis S5**; der Doppelsprung allein (3,41) reicht nicht.
- s 257 **SPRUNG** (q −2,4): Die Sprungfeder trägt auf 6,26 m und damit auf die Oberwurzel (+4,5 bei s 257). Das ist **Geheimnis S4**.
- Auf der Oberwurzel: NORMAL bei s 253, 255,5 und 258 (q −6,5), FRUCHT_MEHRFACH bei s 261.
- s 263 **Stelzenspinne** quer, Weite 2,0: die Abschlussprüfung, Slide auf der Wurzel.
- s 268 TNT (−1,5), NORMAL (0), NORMAL (+1,5).

### F · Kronentor (273–287) – das Ziel unter der Krone

**Aufbau:**
- Ein breites Wurzelregal (8 → 12 m) ragt nach SW aus dem Stamm, y 21, Kurs −150°.
- Die Kronenunterseite liegt 13–15 m darüber.
- Das **Kronentor**, ein Bogen aus zwei Luftwurzeln, steht bei s 280 (Scheitel ≥ 9,5 m, Sichtsperre ab 6 m).
- Zielportal bei s **283** (`saeulen_hoehe` 12 → Spitze y 33, unter der Krone mit ≥ 34).
- Das Regal ist außen offen (tödlich, 16 m tief). Zum Stamm hin und hinter dem Portal steht eine Leitlinie.

**Bild (Schlussbild):**
- Die Kronenunterseite dunkel im oberen Viertel.
- Das Portal mittig; darüber links der Wasserfall (oberer Fall x −0,13, y +0,53, 80 m).
- Dahinter Grat und Kanzel (x −0,26, 154 m), links unten die Furt.
- Blickrichtung SW, also gegen die Sonne: Der Dunst leuchtet (fog_sun_scatter), das Regal liegt selbst in Sonne.

**Spiel:**
- s 274–277 Früchte.
- s 278 **LEBEN** (0).
- s 280,5 NORMAL (−3,0), NORMAL (+3,0).
- Keine Gegner.

---

## 6. Spiel: Lehrfolge, Sprünge, Kisten, Gegner, Checkpoints

### 6.1 Lehrfolge

1. Hüpfen am Mooslog (8).
2. Kisten im Lauf zerdrehen (12).
3. Kröte → **Drehschlag** (18).
4. Stapel → draufspringen (21).
5. Erdspalt → Sprung (25).
6. Erster Checkpoint auf der Kanzel (44).
7. Kerbe neben der offenen Kante (56).
8. Käfer unter der Stufe → **Draufspringen** (69,5).
9. Moosbank als Regelbruch, freiwillig (80–91).
10. Spinne in der Pforte → **Slide** (101,5).
11. Fallkerbe abwärts (118).
12. TNT (127,7).
13. Terrassen mit Käfer (133–145).
14. Nitro allein (168), Spinne auf offener Fläche (170), Furt im Takt (173–183).
15. Zwei Geheimnisse rechts und links (188–193), Kröte (194,5).
16. Die Wendel als Wiederholung von allem, mit verzeihender G1 vor der tödlichen G2.
17. Leben, dann das Ziel.

### 6.2 Sprungtabelle (Pflicht)

| Stelle | s | Art | Weite / Stufe | Höhenunterschied | Reichweite | Reserve |
|---|---|---|---|---|---|---|
| Mooslog | 8 | Hürde | 0,8 m hoch | – | 1,96 | 1,16 |
| Erdspalt | 25,0–27,5 | flach | 2,5 | 0 | 4,47 | 1,97 |
| Kerbe | 56,0–59,0 | leicht ab | 3,0 | −0,17 | 4,57 | 1,57 |
| Fallkerbe | 118,0–121,0 | ab | 3,0 | −0,76 | 4,87 | 1,87 |
| Furt | 173–183 | 3 Hüpfer | 1,77 / 1,97 / 1,71 | 0 | 4,47 | ≥ 2,5 |
| G1 | 210,5–213,5 | auf | 3,0 | +0,51 | 4,16 | 1,16 (nicht tödlich) |
| G2 | 243,0–245,5 | auf | 2,5 | +0,42 | 4,22 | 1,72 |

Stufen nach unten (0,84 / 1,6 / 1,4 m) sind nur zurück Pflicht und bleiben mit
dem Einzelsprung (1,96) machbar.

### 6.3 Geheimnisse

| | Ort | Oberkante | Weg hinauf | Reserve | Einzelsprung? | Inhalt |
|---|---|---|---|---|---|---|
| S1 Moosbank (Regelbruch) | B 83–91, q −6,5…−10 | +2,6 | Feder 3,96 / Doppelsprung 3,41 | 1,36 / 0,81 | nein | 2 NORMAL + FRUCHT_MEHRFACH |
| S2 Findlingsturm | D 188,5–191, q +6…+7,6 | +3,0 | Doppelsprung 3,41 | 0,41 | nein (Slide-Sprung 2,77 nein) | 2 NORMAL |
| S3 Wurzelknie | D 190–193, q −6…−7,6 | +2,4 | Slide-Sprung 2,77 / Doppelsprung | 0,37 / 1,01 | nein | NORMAL + 3 Früchte |
| S4 Oberwurzel hoch | E 257, q −6,5 | +4,5 | Sprungfeder 6,26 | 1,76 | nein | 3 NORMAL + FRUCHT_MEHRFACH (mit S5 geteilt) |
| S5 Oberwurzel tief | E 250–252 | +3,6 | Käfer-Abprall + Doppelsprung 4,03 | 0,43 | nein (Doppelsprung allein 3,41 nein) | wie S4 |

### 6.4 Zählung

| | A | B | C | D | E | F | Summe |
|---|---|---|---|---|---|---|---|
| Kisten | 9 | 13 | 10 | 13 | 14 | 3 | **62** |
| davon CP / FEDER / SPRUNG / TNT / NITRO / SCHUTZ / LEBEN | – | 1 CP, 1 FEDER | 1 CP, 1 TNT | 1 CP, 1 NITRO | 1 CP, 1 SPRUNG, 1 TNT | 1 LEBEN | |
| Gegner | Kröte | Käfer, Spinne | Käfer | Spinne, Kröte | Kröte, Käfer, Spinne | – | **9** (je 3) |
| Checkpoints | – | 44 | 107 | 166 | 232 | – | **4** |

Früchte: 100–120. Linien führen in jede Lektion, Bögen (Scheitel 2,2–2,3 m) liegen
über jeder Lücke, je 3 auf den Trittsteinen. Die Geheimnisse sind mit Früchten
angekündigt.

Kistenregeln:
- Keine schwebenden Kisten.
- Stapel (Oberkante > 1,3 m) nur bei |q| ≥ 2,6.
- Kein hohes Gras näher als 1 m an einer Kiste.

---

## 7. Tiefe und Bildaufbau

**Eine Regel:** Links ist zu, dunkel und nah; rechts ist offen, hell und weit.
Das Offene liegt immer auf derselben Seite, also ist der Abgrund immer lesbar.
Jedes Bild hat ≥ 25 % dunklen Rahmen und einen hellen Pfad (Lesbarkeitsvertrag).

**Bildebenen:**

| Ebene | Inhalt |
|---|---|
| L0 dunkler Rahmen | Äste oben links (≥ 9,5 m), Rahmenfarne unten links, die dunkle Unterseite der Grasnarbe mit Rahmenzacken unten rechts, Stamm und Kronenunterseite (E/F) |
| L1 Spielebene | ausgetretene Erde bzw. helle Wurzelborke. Am hellsten, am wenigsten gesättigt. Kisten heben sich ab. |
| L2 naher Mittelgrund (10–40 m) | Böschung, Schichtfels, nahe Stämme, Wasserfall. Satt. |
| L3 ferner Mittelgrund (40–120 m) | Talkronendach 8–12 m unter dem Grat, Bachglitzern, Talriesen. Mitteldunkel; Tiefennebel ab 12 m. |
| L4 Hintergrund (120–190 m) | Weltenbaum als entsättigte Silhouette, dunkler als der Himmel; Randhügel |
| L5 Himmel | `himmel.gdshader`; ein Schneegipfel im NNO ist freiwillig und nur per Opt-in (Vorgriff auf 02 Frostgrat) |

**Vertikale:**
- Der Weg läuft von 26 m über 7 m auf 21 m.
- Man blickt 20 m hinab (B), zu einer 14-m-Wand hinauf (C), an einem 72-m-Baum hinauf (D) und 16 m von seinen Wurzeln hinab (E/F).
- Vögel fliegen auf dem Grat unter Augenhöhe.

**Wahrzeichenfolge** (gerechnet: x = −1 links … +1 rechts, y = +1 oben; Kamera auf der Wegmitte):

| s | Krone Mitte / Unterseite | Stamm (y 15) | Entfernung | Wasserfall oben | Lichtsäule |
|---|---|---|---|---|---|
| 24 | +0,42/+0,82 · +0,40/+0,60 | +0,39/+0,37 | 180 m | +0,18/+0,50 | +0,25/+0,57 |
| 31 (Enthüllung) | +0,39/+0,83 · +0,38/+0,60 | +0,36/+0,36 | 174 m | +0,15/+0,50 | +0,22/+0,57 |
| 60 | +0,25/+0,94 · +0,24/+0,67 | +0,22/+0,39 | 147 m | +0,01/+0,54 | +0,06/+0,63 |
| 84 | Unterseite +0,17/+0,72 | +0,16/+0,38 | 123 m | −0,10/+0,56 | −0,03/+0,67 |
| 104 | Unterseite +0,12/+0,77 | +0,11/+0,37 | 103 m | −0,28/+0,62 | −0,12/+0,71 |
| 124 | aus dem Bild (oben) | −0,03/+0,51 | 83 m | – | −0,37/+0,98 |
| 148–160 | – | −0,39 … −0,63 (hinter dem Walddach) | 59–49 m | – | – |
| 168–176 | – | −0,77 … −0,95 | 42–36 m | – | – |
| 268 | – | Stamm links, Silhouette ≈ −0,6 | – | −0,43/+0,49 | – |
| 283 (Ziel) | Unterseite überkopf | – | – | −0,13/+0,64 (80 m) | mittig |

Abstand zur Kamera ab s 24 ≤ 180 m, `far` 200 reicht. Auf die Anzeige bei s 8
wird verzichtet: 193 m liegen im vollen Nebel.

**Rahmenregeln:**
- Rahmenbäume rechts stehen nie im ±6°-Kegel der Sichtlinie Kamera→Krone. Der Waldsetzer prüft das je Station.
- Talkronen bleiben ≥ 5 m unter jeder Kante.
- Wurzeltore bei 3, 101,5, 162 und der Kronenbogen bei 280 geben den Takt vor: Jedes kündigt einen neuen Abschnitt an.

---

## 8. Rasen, Kanten, Gelände, Wasser – Technik

### 8.1 Wegdecke ohne Bordstein (`wegboden`)

- `korridor` baut in Level 01 **nur die Decke** (`nur_decke`) samt Trimesh-Kollision (Ebene 1). Es gibt keine Kante und keine Klippe mehr.
- `uv_quer` schreibt UV2 = (q / halbe Breite, s).
- Stufen zwischen Einträgen verschiedener Höhe bekommen eine unsichtbare senkrechte Kollisionsfläche (`stufen_kollision`). Ohne sie fiele man beim Zurückgehen unter die obere Terrasse.

`shaders/wegboden.gdshader` (spatial, gl_compatibility-tauglich, ≤ 5 Samples, kein SCREEN/DEPTH):
- **Maske** m = smoothstep(0,42; 0,62; |uv2.x| + (Rauschen − 0,5)·0,45 − 0,12·sin(uv2.y·0,09)).
  - 0 = Erde, 1 = Rasen.
  - Das Rauschen kommt aus einer 256²-Textur in Weltkoordinaten XZ (FastNoiseLite, feste Saat).
  - Die Spur pendelt, Grasinseln im Weg und Erdflecken im Rasen entstehen von selbst.
- **Trittkante:** ein schmales Band um m = 0,5, ×0,7 dunkler, festgetretene Erde. Dort hängt der Rasen über.
- **Verdeckung** aus uv2.x: Mitte 1,0, am Rand 0,78.
- Die Erde bleibt heller und weniger gesättigt als der Rasen (Weg-Luma ≈ 0,75, Rasen ≈ 55 % davon). Die Spurmitte ist 8 % heller.
- **Makrovariation** im Rasen (1/20 m): Helligkeit ×0,82–1,12, trockene Stellen gelblich. Das bricht die Kachel.
- **Kronenlicht:** Weltrauschen, driftet 0,004/s. Rasen ×0,78–1,08, Pfad ×0,9–1,05. Nur wo `kronenlicht` > 0 (A, C4, D rechts, E, F).
- **Variante `wurzelruecken`** (E/F): helle, abgetretene Borke in der Mitte, Moos an den Flanken. Gleiche Maske.
- Rasentextur und Makrorauschen liegen in `shaders/wald_gemeinsam.gdshaderinc`. Saum, Gelände und Rasenhalme nutzen dieselben Funktionen, damit die Nähte unsichtbar bleiben.

`scripts/wegmaske.gd` (`Wegmaske`) rechnet dieselbe Maske auf der CPU. Die Textur
entsteht **einmal** als Bild über `FastNoiseLite.get_seamless_image(256, 256)` und
wird für die GPU zur `ImageTexture`. CPU und GPU lesen damit Byte für Byte
dasselbe; `NoiseTexture2D` erzeugt asynchron und scheidet deshalb aus.
- `Wegmaske.wert(q_norm, s, welt_xz) -> float` liefert m.
- `Wegmaske.makro(welt_xz) -> float` liefert den Farbfaktor für die Halmfüße.

**Lückenlippen:** Die Pfosten mit Querbalken entfallen. An jeder Lippe liegen 4–6
bündige, helle Kalksteine, an beiden Ecken außerhalb der Spur sitzen warme
Leuchtpilzgruppen. Der Spalt selbst ist dunkel und von weitem lesbar.

### 8.2 Rasen (`Rasensaum`, `Bodenstreu`)

- **Dichte** ∝ m² aus der Wegmaske. Auf der ausgetretenen Spur wächst nichts.
  - Schultern ≈ 9 Büschel/m², Bachwiese 6/m² in der Lauffläche und 10/m² am Rand.
  - Je Büschel 7–9 gebogene Halme (Halmbau wie `Grasfeld`, Windshader).
  - Höhe 0,14–0,38 m, an der Lippe und an Steinen 0,45–0,6 m.
- **Halmfuß = Bodenfarbe** an genau dieser Stelle (Makrorauschen auf der CPU). Die Spitzen sind heller und wärmer, ±8 % Streuung je Instanz. So wachsen Halme aus dem Boden, statt aufgeklebt zu wirken.
- **Innere Reihe** an der Trittkante: 25–40° über die Erde geneigt, hängt 10–20 cm über.
- **Ausblenden:** Die Halmhöhe schrumpft zwischen 28 und 40 m Kameraabstand auf 0 (Vertexshader, Kamera aus INV_VIEW_MATRIX). Dazu harte `visibility_range_end` 42 m. Fade-Modi sind in Compatibility nicht verlässlich.
- **Stücke** zu 24 m entlang s, je Stück und Art ein MultiMesh.
- **Akzente** nach derselben Maske:
  - Klee-Teppiche, Blütengruppen (3–5 je 10 m, auf der Wiese viele);
  - Kiesel an der Lippe;
  - Wispelgras über der Lippe;
  - Farne, Großblätter, Pilze.
- **Rahmenfarne** (1,5–3,5 m): in den unteren Bildecken (links in A, B, C; beidseitig in D), bei |q| ≥ 5,5 und s −3,5 … +0,5 relativ zu einer typischen Figurposition, also 6–10 m vor der Kamera. Nie in den mittleren 40 % des Bildes. Rechts übernehmen dunkle Rahmenzacken, Grasnarbe und Fels diese Rolle.

### 8.3 Kanten (`GelaendeSaum`)

Querschnitt-Sweep je Seite in 1-m-Schritten mit 10–12 Profilpunkten, in Stücken zu 30 m:

- **Lippe** = Kollisionskante. Der Umriss springt per 1D-Rauschen nur **nach außen**, 0–0,35 m.
- **Grasnarbenüberhang** 0,2–0,45 m als eigener Streifen: Gras oben, dunkle Erde unten, Wurzelkarten ≤ 0,8 m (Alpha-Scissor). Die äußere Halmreihe hängt 0,5–0,8 m über.
- **Profiltypen:**

| Typ | Einsatz | Form |
|---|---|---|
| `FELS_AB` | B rechts, C rechts | 70–85°, CPU-3D-Rauschen 0,6–1,4 m, alle 4–6 m ein Sims für Sträucher, dunkle Schmutzkante unter der Lippe |
| `FELS_AUF` | C links, Felsnase | steigt 2 → 14 m; Überhang nur ≥ 10 m über dem Weg; gibt `kronen`-Einträge für `Schluchtsaum.bauen` aus (Farne, Großblätter, Ranken, Wurzeln) |
| `BOESCHUNG` | B links | Erdhang 35–60° mit eingebetteten Steinen und Wurzeln; Nische 78–98 nach Polylinie |
| `UFER` | Furt, Bachkanal C4 | niedrige Erdkante mit Steinen bis zum Wasser |
| `STIRN` | Erdspalt, Kerbe, Fallkerbe, Stufen 66/133/145 | gleiche Fels- oder Erdfläche mit Grasnarbe; der Erdspalt läuft je Seite 5 m in den Waldboden |
| `FLACH` | A, D | nichts; das Gelände schließt bündig an |

- E und F baut der **Weltenbaum** (Wurzelkörper), nicht der Saum.
- `shaders/fels_schichten.gdshader`:
  - weltprojiziertes Triplanar aus `wurzelfels`- und `fels`-Texturen;
  - Schichtbänder aus Welt-Y·0,35 plus niederfrequentem Rauschen, 3–6° geneigt;
  - Moos wo normal.y > 0,55;
  - Verdeckung je Vertex aus Hohlform und Tiefe, zum Fuß hin kühler;
  - Kronenlicht über dem Include.

### 8.4 Gelände (`GelaendeFeld`)

- **Höhenfeld** über x −70…150, z −240…+30 (220 × 270 m). Raster 2,5 m bis 40 m vom Weg, darüber 5 m. Etwa 12 000 Scheitel in 6–8 Stücken, **ohne Kollision**.
- **Formen:**
  - Talmulde (Boden y 3–6);
  - Westhang hinter dem Grat bis y ≈ 40;
  - Klippenkrone über C auf Höhe der Saumkrone;
  - Knoll des Weltenbaums (y 5–8, r 30);
  - Wurzelgruben-Ring auf der N- und O-Seite (Boden y ≈ −2);
  - Bachbett entlang `BACH`;
  - Erdspalt-Kerbe;
  - 2 Oktaven Rauschen ±1,5 m;
  - Randhügel y 30–45 in 100–150 m. Ihre Silhouette brechen skalierte Felsen (ohne Kollision).
- **Scheitelfarben:** R Wiese, G Waldboden, B Fels (Neigung > 40°), A Schlamm/Böschung. Dazu gebackene Abdunklung unter dem Kronendach (dunkler Boden zwischen den Bäumen = Tiefe).
- `shaders/gelaende.gdshader` mischt 4 Texturen mit Welt-UV und nutzt das Include.
- **Nähte:**
  - An `FLACH`-Rändern (A, D) rasten die Scheitel auf die Wegkantenhöhe ein.
  - An `FELS_AB` liegt das Feld unter der Fläche, an `BOESCHUNG`/`FELS_AUF` schließt es an die Krone an, mit 2 m Überlappung.
  - Die Nahtlinie kommt aus `Level01.rand_profil(s, seite)`.
- Die Wurzelwiese und die Furtufer haben flache Zonen genau auf den Höhen der Kollision aus `rohbau`.

### 8.5 Wasser

- **`BACH`:** Tümpel (41,7 | 5 | −103) → (58 | −112) → (76 | −124) → (86 | −134) → **Furt** (72,6 | 7,1 | −145,3; quert D fast rechtwinklig nach NW) → (60 | −157) → (50 | −172, Westfuß des Knolls unter dem Kronentor) → (44 | −195) → (40 | −225).
- **Nachtrag Welle 3 (gelaende):** Das gegrabene Bett folgt `BACH` nicht mehr überall. Der Kanal liegt am Fuß von C3/C4 (`L01Gelaende.KANAL`, statt BACH[1–2]), ein Bogen um die Riesen führt zur Furt (`BOGEN`, statt BACH[3]), und der Ausfluss verlässt das Tal nach Westen. **`wasser` baut nach `L01Gelaende.bachlauf()`** (Punkte mit Wasserspiegel, Bett, Breite, Tödlich-Flags; dazu die Läufe "oberlauf" und "rinne"), nicht nach `Level01.BACH` – sonst schwebt Wasser 20 m draußen über ungegrabenem Tal. Am Tümpel (14 m) lässt der Bachnebel des Geländes Platz für die Gischt; den Nebelstoff stimmt `stimmung` über `L01Gelaende.nebel_stoff()`.
- Eine Kette aus `Wasser`-Rechtecken. **Tödlich** nur in der Furt und im C4-Kanal, sonst Kulisse. Glitzern an; Schaumringe um die Trittsteine.
- `Wasserfall.band(eltern, punkte, breite)` (neu, gleicher Shader) für den oberen Fall (Pfeiler → Becken), das Rauschen unter der Fallkerbe, den unteren Fall (rechte Wand → Tümpel) und das Rinnsal in der Kerbe.
- Gischt als `Staubflug` im Becken, in der Kerbe und am Tümpel.

### 8.6 Begehbares = Optik genau auf Kollision (Findling-Regel)

Jeder Eintrag in `BEGEHBARES` legt die Kollision fest (Kasten, Zylinder oder
Kapsel, Ebene 1 oder 16). Die Optik baut der zuständige Modulhaken und passt sie
exakt darauf:
- `Findling`: ein Superellipsoid mit flacher, bemooster, ausgetretener Oberseite genau auf der Kastenoberkante. Der Fuß ist 1 m versenkt und hat einen Verdeckungsring.
- Brettwurzel, Wurzel, liegender Stamm: Kapsel mit Moospolster.

CC0-Felsmodelle sind nur Deko; ihre Oberseiten sind nie flach.

---

## 9. Modelle

Leitsatz: Die Fremdmodelle liefern die Form, das Level liefert den Stoff.
- `Fremdmodelle.netz()` verschmilzt jedes Modell zu einem ArrayMesh: Transformationen eingebacken, Flächen je Material gruppiert, unbeleuchtete Materialien beleuchtet.
- Bei texturierten Paketen wird getönt, statt die Palette zu tauschen.
- Felsen, Stümpfe und Stämme bekommen die Überlage `moosdecke` (Moos nach Welt-normal.y und Rauschen). So lesen sich Kenney und Quaternius als eine Familie.
- Jeder Streuer ist ein MultiMesh je Fläche und Stück: Borke wirft Schatten, Laub nicht.
- Ohne Dateien oder mit `fremde_modelle = aus` läuft alles über den Rückfall.

| # | Rolle | Einsatz | Primärquelle (CC0) | Rückfall (prozedural) | Menge / Sichtweite / Schatten |
|---|---|---|---|---|---|
| M1 | Hallen- und Hangbäume 12–18 m | A beidseitig, B/C links | MegaKit `CommonTree_1–5`, `Pine_1–3` (UNP `CommonTree`/`PineTree` als Ersatz) | `Riesenstamm` schlank + `Kronenwolke` | ≈ 90 · 90 m · nur Borke |
| M2 | Rahmenbäume | B/C-Simse rechts, Kanzel | MegaKit `TwistedTree_1/3` | `Riesenstamm` gedreht + `Kronenwolke` breit | 8–10 · 90 m · Borke |
| M3 | Talwald nah (von oben gesehen) | Tal ≤ 70 m vom Weg | MegaKit `CommonTree`/`Birch`-Art | `Kronenwolke` (3 Varianten) | ≈ 150 · 0–75 m · keine |
| M4 | Talwald fern | 60–200 m | – | `Kronenwolke` flach, verschmolzen je 25-m-Zelle | ≈ 600 · 60–200 m · keine |
| M5 | Talriesen 32–38 m, Torriesen s 162 | D rechts, Tor | – | `Riesenstamm` (Brettwurzeln) + `Kronenwolke` groß | 5 + 2 · unbegrenzt · Stamm |
| M6 | Weltenbaum | E/F | – | `Weltenbaum` (Code aus `Riesenstamm`) | 1 · nah ≤ 50k Dreiecke, fern (> 110 m) ≈ 8k · Stamm und Äste |
| M7 | Konsolenpilze (Deko) | Stamm, Wurzeln | MegaKit `Mushroom_Laetiporus` | flache `klumpen`-Scheiben | ≈ 40 · 60 m · keine |
| M8 | Felsen, Findlinge (Deko) | Rand, Bachufer, Hügelkämme | MegaKit `Rock_Medium_1–3`, Kenney `rock_largeA–C` (vorhanden) | `Findling`/`Stein` | ≈ 60 · 120 m · nah ja |
| M9 | Kiesel | Lippen, Spur | MegaKit `Pebble_Round_*`/`Pebble_Square_*` | Kenney `rock_small*` / `klumpen` | ≈ 400 · 35 m · keine |
| M10 | Trittsteine, Schwellen | Furt, Lippen | (optisch) MegaKit `RockPath_Round_Wide` | `Findling.scheibe` | 2 + Schwellen |
| M11 | Büsche, Hecken | D rechts, Wurzelwiese, A-Säume | MegaKit `Bush_Common`, `Bush_Common_Flowers` | Kenney `plant_bush*` / `Kronenwolke` klein | ≈ 70 · 60 m · keine |
| M12 | Farne | A, C-Simse, D-Ufer, E-Flanken, Rahmenfarne | MegaKit `Fern_1` | `Farnwerk` (ohne Alpha) | ≈ 150 + 30 groß · 40 m · keine |
| M13 | Großblattpflanzen | C-Fuß, Bach | MegaKit `Plant_1`, `Plant_7` | `Schluchtsaum`-Großblatt | ≈ 40 · 40 m · keine |
| M14 | Blumen, Klee | Schultern, Wiese, F | MegaKit `Flower_3_Group`, `Flower_4_Group`, `Clover_1/2` | Kenney `flower_*` / `Kleinzeug` BLUME, Kleeblatt-Eigenbau | ≈ 300 · 30 m · keine |
| M15 | Gras-Akzente | Lippen, Steine | MegaKit `Grass_Wispy_Tall/Short` | Wispelbüschel aus `Rasensaum` | ≈ 200 · 35 m · keine |
| M16 | Moosstämme, Stümpfe | A-Säume, D | UNP `WoodLog_Moss`, `TreeStump_Moss`; Kenney `log_large`, `stump_old` | `Riesenstamm.liegend` / Stumpf | 12 · 60 m · ja |
| M17 | Totholz | Enthüllungsrahmen, Tal | MegaKit `DeadTree_*` | `Baum` TOTHOLZ | 3 |
| M18 | Pilze | Lippen, Risse | MegaKit `Mushroom_Common`, Kenney `mushroom_*` | leuchtende `klumpen` | ≈ 60 · 30 m · keine |

Budget: ≤ 20 verschiedene Modelle; Texturen VRAM-komprimiert (ETC2/ASTC ist an).
Ziel: VRAM ≤ 140 MB (heute 108,7), `.pck` wächst um ≤ 30 MB.

---

## 10. Licht und Farbe

`Level01.tscn`:
- Sonne unverändert (68°, SSO, Energie 0,6), 2 Stufen, 70 m.
- Tiefennebel 12 → 140 m, Dichte 0,9, sun_scatter 1,6.
- Himmel wie bisher. Optional ein Schneegipfel über neue Uniforms mit Vorgabe 0: Das Bild der anderen Level bleibt pixelgleich.

**Lichtfolge aus dem Kurs:**
- A/B (Kurs N): Die Sonne steht hinten, Frontlicht, gut lesbar.
- C/D (NO): Seitenlicht von rechts. Stammschatten der Riesen liegen schräg über der Wiese.
- E dreht über N nach W, F blickt nach SW: Gegenlicht, der Taldunst leuchtet.

**Stimmungszonen** (relativ; `farbanteil` ≈ 0,6; P `stimmung` stimmt fein):

| Zone | Bereich | nebel_faktor | licht_faktor | Nebelfarbe (Ferne) | Umgebungsfarbe |
|---|---|---|---|---|---|
| A Hallenwald | 0–30 | 1,0 | 0,85 | (0,34 / 0,46 / 0,44) | (0,30 / 0,40 / 0,36) |
| B Hangweg | 30–104 | **0,75** (Nebelende ≈ 183 m, der Baum liest sich) | 1,15 | **(0,52 / 0,66 / 0,74)** kühl-blau | (0,66 / 0,62 / 0,48) warm |
| C Fallklamm | 104–160 | 1,25 | 0,9 | (0,46 / 0,60 / 0,66) | (0,44 / 0,56 / 0,62) |
| D Bachwiese | 160–190 | 1,0 | 1,05 | (0,48 / 0,60 / 0,58) | (0,56 / 0,60 / 0,42) |
| E/F Wendel | Zylinder um die Achse r 36, h 40 | 0,8 | 1,2 | (0,58 / 0,66 / 0,72) | (0,70 / 0,60 / 0,46) |

- Nahes warm, Fernes kühl. Das ist die Luftperspektive, und aus ihr kommt der **kühle Anteil ≥ 10 %** (Ferne, Himmel, Wasser); heute liegt er bei 0–2 %.
- Wasser und Wasserfall tragen den Rest.
- Warme Akzente (Pilze, Blüten, Kisten, Früchte) bleiben unter 6 % der Fläche.

**Lichtschächte** (`Lichtschacht`, `decke` = Öffnung):
- A durch die zwei Dachlöcher (decke = Dachhöhe);
- C über die Felskrone (decke = Krone);
- D durch die Riesen (decke ≈ Kronenunterseite y 24);
- jeweils mit Staub.

**Bewegung:**
- Laubtreiben bei s 20, 50, 90, 150, 235, 260.
- Vögel: zwei Schwärme über dem Tal bei Welt-y 16–20 (B), einer auf Weghöhe bei E, einer unter dem Regal über der Furt (F).

**Farbziele** (`kontaktbogen.py`, alle Stationen):
- Weg-Luma am höchsten;
- größte Einzelfläche dunkel (Böschung, Stämme, Kronendach, Krone);
- kühl ≥ 10 %;
- warm ≤ 55 %.

---

## 11. Kamera- und Kollisionsregeln

| Regel | Inhalt |
|---|---|
| K1 Kamera frei | Über dem Weg innerhalb \|q\| ≤ 6 steht nichts Sichtbares tiefer als 8,8 m (`Schluchtsaum.KAMERA_FREI`). Dächer und Kronen ≥ 9,5 m, Tore ≥ 9,2 m mit Sichtsperre ab 6 m. |
| K2 Sichtschlauch | Zwischen Blickpunkt (s+6, 0,85·q, +1) und Kamera (s−9,5, 0,85·q, +6) liegt nichts auf Ebene 1\|8 außer Boden, Kisten und Sichtsperren. **Alle Leitlinien, Randkörper, das Wurzelfleisch, Wülste und erhöhtes Begehbares liegen auf Ebene 5 (Wert 16) „Spielergrenze“.** Die Figur-Maske wird 1 → 17. Begründung: Der Strahl startet 6 m **vor** der Figur. Eine einrückende Leitwand oder ein Pfortenkörper dazwischen zöge die Kamera **vor** die Figur. |
| K3 Kisten | Kisten liegen auf Ebene 1 (fest). Keine schwebenden Kisten; Stapel > 1,3 m nur bei \|q\| ≥ 2,6. |
| K4 Gefälle | Begehbare Anstiege ≤ 20 % (E 17 %). Bei 20 % liegt der Blickpunkt 0,2 m im Boden, der Austritt nach 0,5 m (unter 1,4 m, harmlos); ab ≈ 28 % würde die Kamera herangeholt. Steiler geht es nur über Stufen oder bergab. |
| K5 Spirale | Der Sehnenschlauch kommt der Achse bis r 17,6 (q −4,4) auf +2,6 m nahe, wenn die Figur am Innenrand steht. Wurzelfleisch bei q −4,4 ≤ +0,6 m; Oberwurzel innen ab q −5,4 mit Unterkante ≥ +3,0; sichtbarer Stamm unter y 36 ≤ r 13. |
| K6 Pfeilhöhe | Kollision in Bögen hält L²/8R + 0,5 m Abstand zum Schlauch (L 15,5: R 22 → 1,37 m, R 60 → 0,50, R 120 → 0,25). |
| K7 Seitenobjekte | Objekte über 0,9 m liegen bündig **außen** an der Wegkante: \|q\| ≥ 0,85 · q_max + 0,8. |
| K8 Rahmenfarne | Nie in den mittleren 40 % des Bildes, nie zwischen Figur und Kamera. |
| K9 Fernebene | Wahrzeichen ≤ 190 m; nur falls Kronenränder abschneiden: `far` 220 **nur** an der Kamera in `Level01.tscn`. |
| K10 Start | s < 9,5 im geschlossenen Wald (Heranholen zeigt Boden und Stämme). |
| K11 Bildtakt | Neue bewegte Knoten sind `PHYSICS_INTERPOLATION_MODE_OFF`; Proben, die die Figur versetzen, rufen `reset_physics_interpolation()`. |

Rückfall, falls Ebene 16 abgelehnt wird: Kanzel, Nische und Pforte
verlieren ihre Einbuchtungen. Die Pforte ist dann ≥ 6,8 m breit (Spinne patrouilliert
2,4 m), die Kanzel ist reine Aussicht hinter dem Geländer, die Moosbank steht
bündig an der Böschung.

---

## 12. Todeszonen und Leitlinien

**Todeszonen** (`Area3D`, Gruppe `todeszonen`, einseitig):
- Oberkante = min(Weg − 6, tiefstes Begehbares im Umriss − 2,5).
- Stürze aus der Probe (26 m rechts, +2 m) landen bei
  - s 10 (25,9 | 28,0 | −6,1),
  - s 45 (28,2 | 27,8 | −36,4),
  - s 90 (40,1 | 25,3 | −73,8),
  - s 135 (57,5 | 18,2 | −103,7),
  - s 180 (89,6 | 9,1 | −125,5),
  - s 225 (115,8 | 14,2 | −193,8).
  Alle liegen auf der offenen Seite über kollisionslosem Gelände. Die Zone darunter muss innerhalb von 42 m Fall (1,5 s) liegen.

| Zone | s | Seite / quer | Oberkante (Welt-Y) |
|---|---|---|---|
| K-A | 0–33 | beidseitig ±(5,6…36) | 20,0 |
| K-Spalt | 24–28,5 | volle Breite | 20,0 |
| K-B | 33–104 | rechts +4,8…+40 | Weg − 6 (20,0 → 16,5) |
| K-Kerbe | 55–60 | volle Breite | 18,5 |
| K-C | 104–150 | rechts +3,8…+40 | Weg − 6 |
| K-Fallkerbe | 117–122 | volle Breite | 14,0 |
| K-Kanal | 145–165 | rechts +4,3…+30 (im Bachbett) | 3,5 |
| K-D | 160–186 | rechts +7,5…+40 | 1,0 |
| K-Furt | 173–183 | Wasser tödlich, darunter ±7 | 5,0 |
| K-Wiese | um die Wurzelwiese | hinter der Heckenleitlinie ab r ≥ 36 | 1,0 |
| K-E | 214–273 | außen +4,6…+40 | Weg − 6 (4,7 → 14,5) |
| K-F | 273–290 | außen und hinter dem Ende | 14,0 |

**Leitlinien** (Ebene 16, 5 m hoch): ±5,6 (A); −5,3 und Nischen-Polylinie (B
links); +5,2 mit Kanzelbucht +9,8 bis s 50 (B rechts); −4,6/−4,9/−5,1 (C links);
±6,8, hinter S2/S3 ±7,8 (D); Hecke der Wurzelwiese (E1); Stammseite und
Endquerwand (F); Querwand hinter dem Start.

---

## 13. Leistungsbudget

**Ziel je Station:**
- Desktop ≤ 700 Draw-Calls und ≤ 750k Primitive (Schatten eingerechnet);
- Web/Handy (`Effekte.reduziert`) ≤ 450;
- VRAM ≤ 140 MB;
- Ladezeit (Ladeprobe) höchstens doppelt so lang wie heute.

Heute liegen die Stationen bei 225–981 Draw-Calls; Spiel und HUD allein kosten ≈ 160–220.

| Modul | Draw-Calls (+ Schatten) | Primitive (mit Schatten) | Mittel |
|---|---|---|---|
| Weg + Lippenmarken | 6 | 10k | 1 Decke, Marken je Lücke verschmolzen |
| Saum | 30 | 50k | 3 Flächen je 30-m-Stück, keine Schatten |
| Gelände | 8 | 30k | 6–8 Stücke, keine Schatten |
| Wasser | 10 | 5k | |
| Weltenbaum | 16 (+6) | 50k (+20k) | Nah/Fern-Wechsel über `visibility_range` |
| Wegbauten | 25 (+10) | 30k | je Abschnitt verschmolzen |
| Wald | 70 (+40) | 180k (+60k) | MultiMesh je Modell × Fläche × Stück; Laub ohne Schatten |
| Rasen + Streu | 40 | 120k | Schrumpfen ab 28 m, Ende 42 m |
| Stimmung | 18 | 10k | Schächte, Staub, Laub, Vögel, Gischt |
| Spiel + HUD | ≈ 200 (+40) | 60k | unverändert |
| **Summe** | **≈ 490–560** | **≈ 600k** | |

**Web/Handy:**
- Gras- und Streudichte ×0,5, Blüten nur bis 20 m;
- Fernwald ×0,6, Laubtreiben halbiert (vorhanden);
- Schatten 60 m (vorhanden);
- MSAA aus auf dem Handy (vorhanden).

**Sichtweiten** (hart):
- Gras 42, Klee/Blumen/Kiesel 30–35, Farne 40, Büsche 60, Hangbäume 90;
- Talwald nah 0–75, fern 60–200;
- Gelände, Weltenbaum-fern und Hügel unbegrenzt.

**Schatten:** Stämme, Borke, Weltenbaumstamm und -äste, Kisten, Gegner und Figur
werfen Schatten. Kein Schatten von Kronen, Laub, Gras, Streu, Saum, Gelände,
Wasser oder Schluchtsaum-Bewuchs.

---

## 14. Risiken

1. **Todeszonen-Überschneidung.** Terrassen, Wiese und Spirale liegen nah beieinander. Gegenmittel: einseitige Zonen, die Oberkantenformel aus Abschnitt 12 und die neue Überschneidungsprobe (`pruefung`).
2. **Sturzprobe.** Die sechs Proben landen im Tal; das Gelände dort bleibt ohne Kollision. TODESHOEHE −12 allein wäre aus y 26 zu langsam.
3. **Lesbarkeit bei hellen Weiten.** Dunst und Himmel können den Pfad überstrahlen. Gegenmittel: mitteldunkles Kronendach, kühle Ferne statt heller Ferne, Nebel erst ab 12 m, Messung per Kontaktbogen.
4. **Ebene 16 und die Figur-Maske** (Player.tscn 1 → 17). Die Änderung ist geteilt; auf anderen Leveln liegt nichts auf Ebene 16. `level_check` und die Bodenstrahlen der Proben müssen 1|16 abfragen. Sollte der Nutzer das ablehnen, gilt der Rückfall aus Abschnitt 11.
5. **Sichtschlauch bei der Moosbank, den Seitenobjekten in D, der Oberwurzel und den Stapeln.** Die Sichtprobe prüft q = −Rand / 0 / +Rand alle 2 m; Kisten- und Bodentreffer meldet sie als Warnung.
6. **Grenzen von gl_compatibility:** kein verlässliches Mesh-LOD, kein Fade, keine Decals, kein Bildschirm- oder Tiefenpuffer. Deshalb harte Sichtweiten, Schrumpfen im Vertexshader, Verdeckung je Vertex, Weltrauschen.
7. **Asset-Hosts blockiert**, oder Namen und Aufbau der Pakete weichen ab. Für jede Rolle gibt es einen prozeduralen Rückfall. Die Namen werden nach dem Download geprüft. Quaternius lädt oft über Google Drive oder itch.io.
8. **VRAM, Download und Dreiecke** der texturierten Pakete auf Handy-Web: ≤ 20 Modelle, ≤ 3k Dreiecke für nahe Bäume, komprimieren, messen.
9. **Glättung 0.34** ändert die Kurvenform gegenüber 0.45. Alle Platzierungen kommen neu aus den Daten und werden geprüft.
10. **Kuppe C1 (−8 → −20 %)**: Die Bodenhaftung (floor_snap 0,1 m gegen 0,042 m je Bild) reicht rechnerisch. Ein Spieltest bestätigt das; die Physik wird nicht angefasst.
11. **Länge** 287 m gegen 236, dazu die offene Kante ab s 50. Gegenmittel: 4 Checkpoints, Reserve ≥ 1,16 m bei jedem Pflichtsprung, Rindenwulst, verzeihende G1.
12. **Lastspitzen beim Aufbau:** Gelände, Sweep und Streuung auf der CPU. Jedes Modul liefert eigene Bauschritte (Ladebalken), Web wird gemessen.
13. **Nähte zwischen Saum und Gelände.** Beide Pakete laufen parallel. Das später gemergte Paket passt die Naht in seinen eigenen Dateien an; `stimmung` prüft das im Bild.
14. **Doku.** README, ARCHITEKTUR, level-vorbilder (.md und .html) und CREDITS müssen nachziehen, sonst bauen spätere Agenten auf falschen Beschreibungen (`doku`).

---

## 15. Schnittstellen (Vertrag, angelegt von `rohbau`)

`scenes/levels/level01.gd` → `class_name Level01 extends LevelBasis`. Die Datei hält
**alle Daten** als `const` und bietet öffentliche Abfragen an:

```
M_WALDSAUM 0, M_HANGWEG 33, M_FALLKLAMM 104, M_BACHWIESE 160, M_WENDEL 198, M_KRONENTOR 273, M_ZIEL 283, M_ENDE 287
PUNKTE, GLAETTUNG (0.34), ABSCHNITTE (mit "hoehe"/"hoehe_ende"/"stoff"/"kronenlicht")
RAENDER        [{von, bis, seite, typ, abstand, hoehe, hoehe_ende, fuss_y, krone_y, nische?}]
BACH           [{punkt: Vector3, bett_y, wasser_y, breite, toedlich}]   # Bett baut L01Gelaende.bachlauf() – wasser liest DAS (8.5)
FAELLE         {"oben": PackedVector3Array, "kerbe": …, "unten": …, "rinnsal": …}
WELTENBAUM     {achse: Vector2(72,-174), r_fuss 12, r_krone 8, krone_mitte_y 54, krone_r 34, unterseite_rand_y 32, unterseite_stamm_y 40}
BEGEHBARES     [{name, form: "kasten"|"zylinder"|"kapsel"|"sweep", s, q, groesse, ebene: 1|16, optik: "wegbauten"|"weltenbaum", …}]
LEITLINIEN     [{punkte: [Vector2(s,q)…], hoehe}]        # Ebene 16
TODESZONEN     [{von, bis, q_von, q_bis, oben_y}]        # Gruppe "todeszonen"
LICHTLOECHER, TORRIESEN, RAHMENBAUM_STELLEN, KISTEN, GEGNER, FRUECHTE
func breite_bei(s), rand_bei(s, sicherheit := 1.3), boden_bei(s) -> float, ist_luecke(s),
     weg_von_der_kante(s, abstand), rand_profil(s, seite) -> Dictionary, pruefprofil() -> Dictionary
```

Module in `scenes/levels/level01/`; `rohbau` legt jedes als Stub an:

| Datei | Klasse | Haken | Eigentümer danach |
|---|---|---|---|
| `boden.gd` | `L01Boden` | `stoff(level, abschnitt) -> Material`, `bauschritte(level) -> Array` | wegboden |
| `saum.gd` | `L01Saum` | `bauschritte(level)` | saum |
| `gelaende.gd` | `L01Gelaende` | `bauschritte(level)`, `hoehe(x, z) -> float` | gelaende |
| `wasser.gd` | `L01Wasser` | `bauschritte(level)` | wasser |
| `weltenbaum.gd` | `L01Weltenbaum` | `bauschritte(level)`, `optik(level, eintrag) -> Node3D` | weltenbaum |
| `wegbauten.gd` | `L01Wegbauten` | `bauschritte(level)`, `optik(level, eintrag) -> Node3D` | wegbauten |
| `wald.gd` | `L01Wald` | `bauschritte(level)` | waldsetzer |
| `rasen.gd` | `L01Rasen` | `bauschritte(level)` | rasen |
| `stimmung.gd` | `L01Stimmung` | `bauschritte(level)` | stimmung |

- Ein Stub liefert `[]` bzw. `null`; dann setzt `rohbau` einen grauen Platzhalter bzw. `Materialbibliothek.waldweg()`.
- `rand_bei`, `weg_von_der_kante` und die Patrouillenklemme behandeln aneinanderstoßende Einträge gleicher Nahthöhe als **durchgehend**. Nur echte Lücken und Stufen (66, 133, 145) sind Kanten. Sonst rückte etwa die Kröte bei 194,5 an die Naht D2/D3.
- `level01.gd` hängt die Bauschritte der Module in fester Reihenfolge an: Weg → Saum → Gelände → Wasser → Begehbares → Weltenbaum → Wegbauten → Wald → Rasen → Boden-Marken → Gefahren, Kisten, Gegner, Früchte, Portale → Stimmung.
- Parametertyp `Level01`. Bei Zyklusproblemen `LevelBasis` + `level.get()`.

Neue geteilte Werkzeuge. Rückwärtskompatibel; ohne neue Schalter bleiben alle Level pixelgleich.
- `LevelWerkzeuge.korridor`: je Eintrag `hoehe`/`hoehe_ende`; Optionen `nur_decke`, `uv_quer`, `stufen_kollision`, `ebene`.
- `LevelWerkzeuge.leitwand(…, seite := 0.0, ebene := 1)`.
- Neu: `LevelWerkzeuge.leitlinie(eltern, kurve, punkte_sq, hoehe, ebene)` und `LevelWerkzeuge.todeszone(eltern, kurve, von, bis, q_von, q_bis, oben_y) -> Area3D`.

---

## 16. Arbeitspakete

Reihenfolge (Wellen):
1. `rohbau`, `holzstein`, `modelle`
2. `pruefung`, `wegboden`, `weltenbaum`, `wegbauten`
3. `saum`, `gelaende`
4. `wasser`, `waldsetzer`, `rasen`
5. `stimmung`
6. `leistung`
7. `doku`

Jedes Paket endet mit `bash werkzeuge/pruefe.sh` → **ERGEBNIS: SAUBER** (alle
Level). Gerendert wird nur gezielt (`FOTO_STELLEN=…`; die CPU ist knapp), und
es wird nur committet, was das Paket besitzt. Neue Skripte samt `.uid`; alle
Texte und Kommentare auf Deutsch. Physikwerte und `corridor_camera.gd` bleiben
unberührt.

### P1 `rohbau` – Kurve, Weg, Daten, Graubox, Spiel
- **Besitz:**
  - `scenes/levels/level01.gd` (neu geschrieben);
  - `scenes/levels/level01/*.gd` (nur Stubs; danach gehen sie an die Pakete);
  - `scripts/level_werkzeuge.gd`;
  - `scenes/player/Player.tscn` (nur `collision_mask` 1 → 17);
  - `werkzeuge/schaufenster.sh` (Stationen).
- **Inhalt:**
  - Kurve aus Abschnitt 3, `ABSCHNITTE` aus Abschnitt 4, alle Datentabellen aus Abschnitt 15.
  - Weg über `korridor` mit `nur_decke`, `uv_quer`, `stufen_kollision`.
  - `BEGEHBARES` mit Kollision auf der richtigen Ebene, graue Platzhalter.
  - Innenflanke und Rindenwulst in E, Wurzelwiese, Furtsteine als Zylinder, Mooslog als Kapsel.
  - Leitlinien auf Ebene 16, einseitige Todeszonen (Gruppe `todeszonen`).
  - Portale, mit Lichtsäule 12 m.
  - **Alle** Kisten, Gegner und Früchte aus Abschnitt 5/6 als Tabellen mit Platzierungshelfern (`_kiste`, `_gegner` mit Klemmen, Fruchtreihe und -bogen).
  - `pruefprofil()` gibt `{"sicht": true, "gefaelle": true, "todeszonen": true}` zurück.
  - Web-Schattenstufen wie bisher in `_nach_aufbau`.
  - Alte Level-01-Funktionen (Schluchtwand, Simse, Kronenwald, Rankenwerk, Wegdeko, Pfosten) entfallen; die Werkzeuge selbst bleiben für andere Level.
  - Stationen: l01 `4,31,46,70,101,119,140,176,212,249,281`, l01seite `60,186`, l01nah `52`.
  - ARCHITEKTUR-Eintrag für Ebene 5 als Querwunsch an `doku`.
- **Abnahme:**
  - `pruefe.sh` ist SAUBER, alle Kisten und Gegner stehen auf Boden, die 6 Sturzproben greifen.
  - Das Level ist von Anfang bis Ende durchspielbar (Spieltest-Rauchlauf `TEST_LEVEL=1`).
  - Die Richtzeit ist 94–95 s (Zeittafel).
  - Andere Level sind unverändert (Schaufenster Hub und Splash pixelgleich).

### P2 `pruefung` – neue Proben (Opt-in)
- **Besitz:** `werkzeuge/level_check.gd`. Danach, nur für die Spieltabellen (KISTEN, GEGNER, FRUECHTE, Oberkanten in TODESZONEN), `level01.gd`, bis `leistung` beginnt.
- **Inhalt:**
  - **Sichtprobe:**
    - Sie rechnet die Kameramathe nach: Strecke, Heranholen, Höhe, seitlich 0,85.
    - Getestet wird alle 2 m, bei q = −Rand/0/+Rand. Die Figurhöhe kommt per Bodenstrahl (1|16).
    - Strahl vom Blickpunkt zur Wunschposition, Maske 1|8, wie `_freie_sicht`.
    - FEHLER, wenn die Kamera um > 1,5 m herangeholt würde oder vor die Figur käme. Treffer auf Kisten meldet sie als WARNUNG.
    - Einmalig wird sie gegen die echte Kamera abgeglichen: Figur an 3 Stellen setzen, `reset_physics_interpolation()`, einschwingen lassen, Abweichung < 0,2 m.
  - **Gefälleprobe:** meldet, wo der Blickpunkt > 0,3 m unter dem Boden liegt.
  - **Todeszonenprobe:** begehbare Punkte (alle 2 m, 3 Querlagen, +0,9 m, dazu die Oberseiten aus `BEGEHBARES`) dürfen in keiner Zone der Gruppe `todeszonen` liegen.
  - Bodenstrahlen für Kisten und Gegner fragen 1|16 ab.
  - Nur aktiv, wenn das Level `pruefprofil()` meldet: Die anderen 24 Level bleiben unberührt.
  - Befunde in Level 01 werden in den Spieltabellen behoben; Geometriebefunde gehen als Liste an `leistung`.
- **Abnahme:** `pruefe.sh` SAUBER. Eine absichtlich falsch gesetzte Testkiste im Schlauch und eine Zone über der Wiese werden gemeldet (danach wieder entfernt). Die Laufzeit der Stufe 3 wächst um ≤ 60 s.

### P3 `wegboden` – Wegdecke, Maske, gemeinsames Shader-Include, Lückenlippen
- **Besitz:** `shaders/wegboden.gdshader`, `shaders/wald_gemeinsam.gdshaderinc`, `scripts/wegmaske.gd`, `scenes/levels/level01/boden.gd`.
- **Inhalt:**
  - Abschnitt 8.1 vollständig: Maske, Trittkante, Verdeckung, Makrovariation, Kronenlicht, Variante `wurzelruecken`.
  - CPU-Maske identisch zur GPU, über ein gemeinsames Bild.
  - `L01Boden.stoff()` je Abschnitt.
  - Lückenlippen: bündige Kalksteine und Leuchtpilzgruppen, je Lücke verschmolzen und ohne Schatten.
  - Das Include stellt `rasen_farbe(welt_xz)`, `makro(welt_xz)` und `kronenlicht(welt_xz, t)` bereit.
- **Abnahme:**
  - Nahaufnahme s 52 und Verfolger s 31/176: kein Bordstein, die Spur pendelt, die Grasinseln wirken glaubwürdig.
  - Eine Einheitsprobe vergleicht `Wegmaske.wert` mit dem Shaderergebnis an 20 Punkten (≤ 0,02).
  - Draw-Calls ≤ 6.

### P4 `holzstein` – prozedurale Helden und Rückfälle
- **Besitz:** `scenes/props/riesenstamm.gd`, `scenes/props/kronenwolke.gd`, `scenes/props/findling.gd`, `scenes/props/farnwerk.gd`, `werkzeuge/propschau.gd` (+ `Propschau.tscn`).
- **Inhalt:**
  - **`Riesenstamm`:**
    - 16–24 Segmente, Ringe 1,5–4 m, 12–20 gedrehte Borkenrippen;
    - 5–8 Brettwurzeln (Reichweite 1,5–3,5 m, 2–5 m hoch), Moos auf der Nordseite und unten;
    - Konsolenpilze, Efeu, Scheitelfarben für Verdeckung und Moosmaske;
    - `liegend()` mit Kapsel und Bruchsplittern; die Variante `schlicht` (8 Seiten) für MultiMesh-Reihen.
  - **`Kronenwolke`** (kein Blob):
    - 5–9 verrauschte Ikosphären, verschmolzen; Normalen zu 70 % zur Kronenmitte (weiche Wolkenschattierung);
    - Verdeckung und Helligkeit nach Tiefe und Höhe;
    - 30–60 Blattkarten mit Alpha-Scissor am Umriss;
    - 3 Varianten und eine flache Fernvariante, 1,5–3k Dreiecke.
  - **`Findling`:** Superellipsoid auf einen Kasten eingepasst, Oberseite flach genau auf der Kastenoberkante, bemoost und ausgetreten, Fuß 1 m versenkt, Verdeckungsring. Dazu `scheibe()` für Trittsteine auf Zylindern.
  - **`Farnwerk`:** klein, groß (2–3,5 m) und Rahmenfarn, verallgemeinert aus Schluchtsaum-Farn und -Wedel, ohne Alpha, für MultiMesh.
  - Alles statisch, ohne `_process`.
- **Abnahme:**
  - Propschau-Aufnahme jedes Bauteils.
  - Dreieckszahlen dokumentiert: Stamm nah ≤ 6k, schlicht ≤ 300, Krone ≤ 3k.
  - `pruefe.sh` SAUBER.

### P5 `modelle` – CC0-Pakete und `Fremdmodelle.netz`
- **Besitz:** `assets/modelle/natur2/**` (Modelle, Lizenztexte, LIESMICH), `assets/CREDITS.md`, `scripts/fremdmodelle.gd`, `werkzeuge/modellschau.gd`.
- **Inhalt:**
  - Pakete laden (Einkaufsliste), ≤ 20 Modelle nach Abschnitt 9 auswählen, Namen prüfen.
  - Nur glTF/GLB ohne Draco oder Meshopt; Texturen VRAM-komprimiert importiert.
  - `Fremdmodelle.netz(bezeichnung, optionen) -> {mesh, huelle, krone_unten, flaechen}`: verschmolzen, je Material gruppiert, Beleuchtung repariert, tönbar.
  - `Fremdmodelle.moosdecke()`.
  - `hat()`/`aktiv()` bleiben.
  - Modellschau für natur2; VRAM- und `.pck`-Zuwachs messen.
  - **Sind die Hosts gesperrt:** `netz()` samt leerem natur2 mit LIESMICH liefern; die Rückfälle greifen.
- **Abnahme:**
  - Modellschau-Bilder ohne rosa oder unbeleuchtete Flächen.
  - Jede Datei hat eine CREDITS-Zeile, ein Lizenztext liegt daneben.
  - `PRUEF_ASSETS=0` und `=1` sind beide SAUBER.

### P6 `weltenbaum` – der Riese und die Wendel
- **Besitz:** `scenes/props/weltenbaum.gd`, `scenes/levels/level01/weltenbaum.gd`.
- **Inhalt:**
  - **Stamm:** Code aus `Riesenstamm`, Ø 24 → 16 m bis y 36, Borke in Weltprojektion.
  - Brettwurzeln laufen in den Knoll und die Gruben aus; 4–5 Äste; Kronenschirm aus `Kronenwolke`-Clustern (r 34, Unterseite 32–40, Oberseite 72, **ohne Schatten**).
  - Konsolenpilze, Leuchtpilze, Efeu, Moosstreifen.
  - **Wurzelkehle:** Innenfleisch, Rindenwulst, Wurzelkörper unter dem Weg bis ins Gelände, Brüche G1/G2, Oberwurzel, Wurzelregal F, Kronentor-Bogen (Sichtsperre ab 6 m).
  - Alles passgenau auf die Kollision aus `rohbau` (`optik()`).
  - Fernfassung ≈ 8k Dreiecke ab 110 m.
  - Einhaltung von K5.
- **Abnahme:**
  - Verfolger 212/249/281 und Blick vom Grat (s 60).
  - Sichtprobe auf E/F ohne Fehler, Figur am Innenrand.
  - ≤ 16 Draw-Calls (+6 Schatten).

### P7 `wegbauten` – Setpieces am Weg
- **Besitz:** `scenes/levels/level01/wegbauten.gd`, neu `scenes/props/totholzzaun.gd`.
- **Inhalt:**
  - Wurzelnest am Start mit Rückwand, Wurzeltore bei s 3, 101,5 und 162 (`Schluchtsaum.wurzeltor`).
  - Mooslog, toter Baum und Findling als Enthüllungsrahmen.
  - Totholzgeländer mit geborstenem Endpfosten, Kanzel-Platte mit Drehkiefer.
  - Moosbank und Nischenboden, Felsnase, Pfortenkörper, Torbaum.
  - Furtsteine (`Findling.scheibe`), Wurzelknie, Findlingsturm.
  - Wurzeln im Erdspalt und in der Kerbe (`Schluchtsaum._strang`-artig).
  - Alles über `optik()` passgenau auf `BEGEHBARES`.
- **Abnahme:** Verfolger 4/31/46/101/176, keine grauen Platzhalter mehr außerhalb von E/F, Sichtprobe an Pforte und Nische ohne Fehler.

### P8 `saum` – Kanten und Felswände
- **Besitz:** `scripts/gelaende_saum.gd`, `shaders/fels_schichten.gdshader`, `scenes/levels/level01/saum.gd`.
- **Inhalt:**
  - Abschnitt 8.3: alle Profiltypen, Lippe, Grasnarbenüberhang, Wurzelkarten, Stirnflächen für Lücken und Stufen, Nische nach Polylinie.
  - `kronen`-Einträge für C links → `Schluchtsaum.bauen` (Farne, Großblätter, Ranken, Wurzeln).
  - Abfrage `GelaendeSaum.flaeche_punkt(s, seite, hoehe) -> Vector3` für `wasser`.
  - Keine Würfel.
- **Abnahme:** Seitenansicht s 60 zeigt modellierte Schichtwand statt Blöcke; Verfolger 70/119/140; ≤ 30 Draw-Calls; die Naht zu `gelaende` ist sauber, sofern schon gemergt.

### P9 `gelaende` – Tal, Knoll, Gruben, Hügel
- **Besitz:** `scripts/gelaende_feld.gd`, `shaders/gelaende.gdshader`, `scenes/levels/level01/gelaende.gd`.
- **Inhalt:**
  - Abschnitt 8.4: Höhenfunktion `L01Gelaende.hoehe(x, z)`, Stücke mit Raster 2,5/5 m, Scheitelfarben, gebackene Walddunkelung.
  - Bachbett, Nähte nach `rand_profil`, flache Zonen für Wiese und Ufer.
  - Randhügel mit Kammfelsen (Kenney-Felsen oder `Findling`).
  - Keine Kollision.
- **Abnahme:**
  - Verfolger 31/176/281: das Tal liest sich über 150 m, kein Horizont im Leeren.
  - Sturzproben landen weiter in Zonen.
  - ≤ 8 Draw-Calls.

### P10 `wasser` – Bach und Wurzelfall
- **Besitz:** `scenes/props/wasserfall.gd` (nur additiv `band()`), `scenes/levels/level01/wasser.gd`.
- **Inhalt:**
  - Abschnitt 8.5: Wasser-Kette entlang `BACH` (tödlich nur Furt und Kanal), Schaumringe.
  - Oberer Fall, Kerbenrauschen, unterer Fall, Tümpel, Rinnsal in der Kerbe, Gischt.
  - Die Fälle folgen der Saumfläche (`flaeche_punkt`).
- **Abnahme:** Verfolger 31/119/176; der Wasserfall ist vom Grat und vom Ziel aus lesbar; die Furt tötet und Hüpfen über die Steine geht (Spieltest); ≤ 10 Draw-Calls.

### P11 `waldsetzer` – Wald in drei Tiefen
- **Besitz:** `scripts/waldsetzer.gd`, `scenes/levels/level01/wald.gd`.
- **Inhalt:**
  - **Generischer MultiMesh-Setzer:** Modell über `Fremdmodelle.netz` oder Rückfall aus `holzstein`, je Fläche ein MultiMesh je Stück bzw. Zelle; Sichtweiten und Schattenpolitik.
  - Tönung je Instanz, Mindestabstand, Bodenhöhe über `L01Gelaende.hoehe`.
  - **Ausschlüsse:** Wegschlauch und K1-Hülle (Kronen über \|q\| < 6 erst ab 9,5 m), der ±6°-Kegel zur Krone.
  - **Level 01:**
    - Hallenwald A mit Dachlöchern aus `LICHTLOECHER`, Hangwald B/C;
    - Rahmenbäume auf den Simsen;
    - Talwald nah und fern, Talriesen und Torriesen (`TORRIESEN`);
    - Hecken und Büsche, Deko-Felsen, Moosstämme, Stümpfe, Totholz im Tal.
- **Abnahme:**
  - Verfolger 4/31/70/140/176, auch mit `FOTO_ASSETS=0` (Rückfall ohne Blobs).
  - Keine Krone tiefer als erlaubt.
  - Wald ≤ 70 (+40) Draw-Calls und ≤ 240k Primitive an jeder Station.

### P12 `rasen` – Rasen, Streu, Rahmenfarne
- **Besitz:** `scenes/props/rasensaum.gd`, `scenes/props/bodenstreu.gd`, `scenes/levels/level01/rasen.gd`.
- **Inhalt:**
  - Abschnitt 8.2: Rasensaum nach der Wegmaske, Halmfuß in Bodenfarbe, geneigte Innenreihe, Wispelgras an der Lippe, Schrumpfen ab 28 m.
  - Klee, Blumen, Kiesel, Farne, Großblätter, Pilze; Rahmenfarne nach K8.
  - Freiraum um Kisten, Moos und Farn in den Rissen von E/F.
  - Web-Reduktion.
- **Abnahme:** Nahaufnahme s 52, Verfolger 31/176; ≤ 40 Draw-Calls und ≤ 120k Primitive; Kisten bleiben frei sichtbar.

### P13 `stimmung` – Licht, Nebel, Bewegung, Farbziele
- **Besitz:**
  - `scenes/levels/Level01.tscn`, `scenes/levels/level01/stimmung.gd`;
  - `shaders/himmel.gdshader` (nur Opt-in-Uniforms, freiwillig);
  - `scenes/ui/splash_kulisse.gd` (nur falls sich das Grundlicht ändert).
- **Inhalt:**
  - Abschnitt 10: Stimmungszonen (E/F als Zylinder), Lichtschächte, Staub, Laubtreiben, Vögel.
  - Nebel- und Umgebungswerte auf die Farbziele stimmen.
  - Nähte Saum↔Gelände im Bild prüfen und melden.
- **Abnahme:**
  - Voller Schaufenstersatz l01/l01seite/l01nah.
  - `kontaktbogen`: Weg-Luma an jeder Station am höchsten, kühl ≥ 10 %.
  - Hub und Splash pixelgleich.

### P14 `leistung` – Messen, Web, Endabnahme des Spiels
- **Besitz:** `scenes/levels/level01.gd` und alle `scenes/levels/level01/*.gd` für das Feinstimmen; `werkzeuge/foto.gd` und `werkzeuge/kontaktbogen.py`, falls ein Schalter für das Web-Messen nötig ist.
- **Inhalt:**
  - Alle Stationen am Desktop und reduziert messen; Budgets aus Abschnitt 13 einhalten (Dichten, Sichtweiten, Schatten).
  - VRAM und Ladeprobe messen.
  - Geometriebefunde aus `pruefung` beheben.
  - Spieltest-Rauchlauf, jeder Pflichtsprung einmal von Hand im Bot oder mit einer Probe nachgewiesen.
  - Messwerte als Tabelle an `doku`.
- **Abnahme:** ≤ 700 / ≤ 450 Draw-Calls, ≤ 750k Primitive, VRAM ≤ 140 MB; `pruefe.sh` SAUBER mit `PRUEF_ASSETS=0` und `=1`; Glattprobe ohne neue ZITTERT/STUFT.

### P15 `doku` – Beschreibung und Prüfstand
- **Besitz:** `README.md`, `ARCHITEKTUR.md`, `doku/level-vorbilder.md`, `doku/level-vorbilder.html`, `scenes/levels/werkstatt.gd`; `assets/CREDITS.md` nur Prüfung (nach `modelle`).
- **Inhalt:**
  - README Level 01: neue Abschnittstabelle, 62 Kisten, 9 Gegner, 4 Checkpoints, Stationen, Messwerte.
  - ARCHITEKTUR:
    - Kollisionsebene 5 „Spielergrenze“, `korridor`/`leitwand`/`leitlinie`/`todeszone`;
    - Modulaufbau von Level 01; neue Bauteile, Gelände, Weltenbaum, Rasensaum, Waldsetzer;
    - Stoffe, die bei ihren Bauteilen liegen (wie `Schluchtsaum.wurzelholz`).
  - level-vorbilder: Werkzeugliste um die neuen Bauteile ergänzen; „Rahmenzacken“ schließen.
  - Werkstatt-Stationen für Saum, Findling, Riesenstamm, Kronenwolke, Rasensaum.
  - Die CLAUDE.md-Zeile zu Level 01 bleibt; der Name ist unverändert.
- **Abnahme:** `pruefe.sh` SAUBER; in der Doku gibt es keine veralteten Zahlen mehr (Suche nach „236 m“, „45 Kisten“, „14 Gegner“).

**Abhängigkeiten:**

| Paket | hängt ab von |
|---|---|
| rohbau, holzstein, modelle | – |
| pruefung, wegboden | rohbau |
| weltenbaum, wegbauten | rohbau, holzstein |
| saum, gelaende | rohbau, wegboden |
| wasser | saum, gelaende |
| waldsetzer | saum, gelaende, holzstein, modelle |
| rasen | wegboden, saum, holzstein, modelle |
| stimmung | wasser, weltenbaum, wegbauten, waldsetzer, rasen, pruefung |
| leistung | stimmung |
| doku | leistung |

---

## 17. Schaufenster und Gesamtabnahme

- **Stationen:**
  - l01 `4, 31, 46, 70, 101, 119, 140, 176, 212, 249, 281`: Start, Enthüllung, Kanzel, Käfer an der Stufe, Pforte, Fallkerbe, Terrassen, Furt, G1, Oberwurzel, Ziel;
  - l01seite `60, 186`: Felswand, Wiese und Stammfuß;
  - l01nah `52`: Rasen und Lippe.
- **Das Level ist fertig, wenn:**
  1. Kein Bild einen Bordstein, eine Würfelwand oder eine Blobkrone zeigt.
  2. Jede Station einen dunklen Rahmen, einen hellen Pfad und (außer A) Tiefe über 100 m hat.
  3. Das Budget aus Abschnitt 13 eingehalten ist.
  4. `pruefe.sh` SAUBER meldet, samt der neuen Proben.
  5. Die Lehrfolge im Spieltest ohne Pflicht-Doppelsprung aufgeht.

---

## 18. Einkaufsliste Modelle (für `modelle`)

| Paket | Host | Lizenz | Nehmen (Namen nach dem Download prüfen) |
|---|---|---|---|
| Quaternius **Stylized Nature MegaKit** (Standard, kostenlos) | quaternius.com (Paketseite). Der Download-Knopf führt oft zu **drive.google.com / drive.usercontent.google.com** oder **quaternius.itch.io**; diese Hosts ebenfalls freigeben | CC0 | `CommonTree_1–5`, `Pine_1–3`, `TwistedTree_1/3`, `DeadTree_1/2`, `Bush_Common`, `Bush_Common_Flowers`, `Fern_1`, `Plant_1`, `Plant_7`, `Flower_3_Group`, `Flower_4_Group`, `Clover_1/2`, `Grass_Wispy_Tall/Short`, `Mushroom_Common`, `Mushroom_Laetiporus`, `Rock_Medium_1–3`, `Pebble_Round_*`/`Pebble_Square_*`, `RockPath_Round_Wide` (glTF, gemeinsame Texturatlanten) |
| Quaternius **Ultimate Nature Pack** | quaternius.com; Einzelmodelle als Spiegel auf **poly.pizza** (static.poly.pizza) | CC0 | `WoodLog_Moss`, `TreeStump_Moss`. Ersatzbäume `CommonTree_*`/`PineTree_*`/`BirchTree_*`, falls das MegaKit fehlt |
| Kenney **Nature Kit** (vollständig) | kenney.nl/assets/nature-kit (ZIP direkt) | CC0 | `stump_old`, `stump_round`, `log_large`; dazu die 35 vorhandenen (`rock_large*`, `plant_bush*`, `flower_*`, `mushroom_*`) |
| poly.pizza | poly.pizza | **nur Modelle mit ausdrücklichem CC0-Vermerk** | nur als Spiegel für die oben genannten Quaternius-Modelle |

- Ablage: `assets/modelle/natur2/<paket>/…`, Lizenztext je Paket daneben, eine Zeile in `assets/CREDITS.md`.
- glTF/GLB ohne Draco oder Meshopt; Texturen VRAM-komprimiert (ETC2/ASTC ist im Projekt an).
- Höchstens 20 Modelle; nahe Bäume ≤ 3k Dreiecke; Ziel VRAM ≤ 140 MB, `.pck` wächst um ≤ 30 MB.

**Rückfall je Bedarf**, falls ein Host gesperrt bleibt:

| Bedarf | Rückfall |
|---|---|
| Bäume (Halle, Hang, Rahmen, Tal nah) | `Riesenstamm` + `Kronenwolke` |
| Talwald fern | `Kronenwolke` flach |
| Riesen, Weltenbaum | immer prozedural |
| Konsolenpilze | `klumpen`-Scheiben |
| Felsen | `Findling`/`Stein` |
| Kiesel | Kenney `rock_small*`/`klumpen` |
| Trittsteine | `Findling.scheibe` |
| Büsche | Kenney `plant_bush*`/`Kronenwolke` klein |
| Farne | `Farnwerk` |
| Großblatt | `Schluchtsaum`-Großblatt |
| Blumen, Klee | Kenney `flower_*`/`Kleinzeug`/Eigenbau-Klee |
| Wispelgras | `Rasensaum` |
| Stämme, Stümpfe | `Riesenstamm.liegend` / Kenney `log_large` |
| Totholz | `Baum` TOTHOLZ |
| Pilze | Kenney `mushroom_*`/Leucht-`klumpen` |
